-- i'm too lazy to configure the VS solution, so here's an xmake file for now
local version = "4.8"
local name = "PapyrusUtil"

local sksevr_dir = "./extern/sksevr_2_00_12/src"

set_project(name)
set_version(version)

set_arch("x64")
set_languages("c++17")

add_rules("mode.debug", "mode.releasedbg")
set_defaultmode("releasedbg")

add_rules("plugin.compile_commands.autoupdate")

set_runtimes(is_mode("debug") and "MTd" or "MT")

add_requires("boost", {configs = {filesystem = true, random = true}})

target(name)
	set_kind("shared")
	add_packages("boost")

	add_defines("IS_VR")
	add_includedirs(sksevr_dir, sksevr_dir .. "/sksevr", ".", "extern/SkyrimVRESL")
	add_forceincludes("common/IPrefix.h")
	add_syslinks("comdlg32", "winmm")

	add_files(
		"ActorUtil.cpp",
		-- "Asm.cpp", -- dead code
		"Data.cpp",
		"External.cpp",
		"Forms.cpp",
		"jsoncpp.cpp",
		"JsonUtil.cpp",
		"main.cpp",
		"MiscUtil.cpp",
		"Offsets.cpp",
		"PackageData.cpp",
		"PapyrusUtil.cpp",
		"Plugin.cpp",
		"Serialize.cpp",
		"StorageUtil.cpp"
	)
	add_files("extern/SkyrimVRESL/SkyrimVRESLAPI_SKSE.cpp")
	add_files("exports.def")

	add_files(path.join(sksevr_dir, "common/*.cpp"))
	add_files(path.join(sksevr_dir, "sksevr/skse64_common/*.cpp"))
	for _, file in ipairs({
		"GameAPI.cpp",
		"GameBSExtraData.cpp",
		"GameData.cpp",
		"GameExtraData.cpp",
		"GameFormComponents.cpp",
		"GameForms.cpp",
		"GameReferences.cpp",
		"GameRTTI.cpp",
		"GameSettings.cpp",
		"GameTypes.cpp",
		"GameUtilities.cpp",
		"HashUtil.cpp",
		"NiObjects.cpp",
		"PapyrusArgs.cpp",
		"PapyrusInterfaces.cpp",
		"PapyrusVM.cpp",
	}) do
		add_files(path.join(sksevr_dir, "sksevr/skse64", file))
	end

	after_build(function(target)
        import("utils.archive")

        local source_data_dir = path.join(os.projectdir(), "data")
        local source_data_files = os.files(path.join(source_data_dir, "**"))

        local dist_dir = path.absolute(vformat("$(builddir)/dist"))
        local archive_name = name .. "-VR"
        local dist_mod_dir = path.join(dist_dir, archive_name)
        local dist_archive = path.join(dist_dir, archive_name .. "-" .. target:version() .. ".zip")
        os.tryrm(dist_dir)

        local target_dirs = {
            "C:/Games/MySkyrimVR-New/mods/" .. archive_name,
            dist_mod_dir,
        }
        for _, target_dir in ipairs(target_dirs) do
            local target_plugin_dir = path.join(target_dir, "SKSE", "Plugins")
            os.mkdir(target_plugin_dir)
            os.cp(target:targetfile(), target_plugin_dir)
            os.cp(target:symbolfile(), target_plugin_dir)

            for _, file in ipairs(source_data_files) do
                local target_file = path.join(target_dir, path.relative(file, source_data_dir))
                os.mkdir(path.directory(target_file))
                os.cp(file, target_file)
            end
            print("Deployed into " .. target_dir)
        end

        archive.archive(dist_archive, "*", {curdir = dist_mod_dir})
        print("Packaged " .. dist_archive)
	end)
target_end()
