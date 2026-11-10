#!/usr/bin/env python3
"""Regenerate the checked-in Xcode project. Python standard library only."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "CallSignal.xcodeproj"


def uid(name):
    return hashlib.sha256(name.encode()).hexdigest()[:24].upper()


def quoted(value):
    return json.dumps(str(value))


def generate():
    sources = sorted(str(p.relative_to(ROOT)) for folder in ["App", "Sources/CallSignalCore"]
                     for p in (ROOT / folder).rglob("*.swift"))
    resources = ["App/Assets.xcassets", "App/PrivacyInfo.xcprivacy"]
    extras = ["App/Info.plist", "README.md", "LICENSE"]
    objects = []

    def obj(key, value):
        objects.append(f"\t\t{uid(key)} = {{ {value} }};")

    def ids(names):
        return "(" + ", ".join(uid(n) for n in names) + ");"

    for path in sources + resources + extras:
        filetype = ("sourcecode.swift" if path.endswith(".swift") else
                    "folder.assetcatalog" if path.endswith(".xcassets") else
                    "text.plist.xml" if path.endswith((".plist", ".xcprivacy")) else "text")
        obj("file:" + path, f"isa = PBXFileReference; lastKnownFileType = {filetype}; path = {quoted(path)}; sourceTree = \"<group>\";")
    for path in sources + resources:
        obj("build:" + path, f"isa = PBXBuildFile; fileRef = {uid('file:' + path)};")

    obj("product", 'isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = CallSignal.app; sourceTree = BUILT_PRODUCTS_DIR;')
    obj("app-group", "isa = PBXGroup; name = App; children = " + ids("file:" + p for p in sources + resources + extras) + ' sourceTree = "<group>";')
    obj("products", "isa = PBXGroup; name = Products; children = " + ids(["product"]) + ' sourceTree = "<group>";')
    obj("main-group", "isa = PBXGroup; children = " + ids(["app-group", "products"]) + ' sourceTree = "<group>";')

    obj("sources", "isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = " + ids("build:" + p for p in sources) + " runOnlyForDeploymentPostprocessing = 0;")
    obj("resources", "isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = " + ids("build:" + p for p in resources) + " runOnlyForDeploymentPostprocessing = 0;")
    obj("frameworks", "isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;")

    obj("target", f"isa = PBXNativeTarget; buildConfigurationList = {uid('target-config-list')}; buildPhases = " + ids(["sources", "frameworks", "resources"]) + f" buildRules = (); dependencies = (); name = CallSignal; productName = CallSignal; productReference = {uid('product')}; productType = \"com.apple.product-type.application\";")

    project_settings = {
        "CLANG_ENABLE_MODULES": "YES", "CLANG_ENABLE_OBJC_ARC": "YES",
        "IPHONEOS_DEPLOYMENT_TARGET": "17.0", "SDKROOT": "iphoneos",
        "SWIFT_VERSION": "5.0", "SWIFT_STRICT_CONCURRENCY": "targeted",
        "GCC_C_LANGUAGE_STANDARD": "gnu17", "ENABLE_USER_SCRIPT_SANDBOXING": "YES"
    }
    target_settings = {
        "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
        "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
        "CODE_SIGN_STYLE": "Automatic", "CURRENT_PROJECT_VERSION": "1",
        "DEVELOPMENT_TEAM": "", "GENERATE_INFOPLIST_FILE": "NO",
        "INFOPLIST_FILE": "App/Info.plist", "MARKETING_VERSION": "1.0.0",
        "PRODUCT_BUNDLE_IDENTIFIER": "org.callsignal.app",
        "PRODUCT_NAME": "$(TARGET_NAME)", "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
        "SUPPORTS_MACCATALYST": "NO", "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO",
        "TARGETED_DEVICE_FAMILY": "1", "ENABLE_PREVIEWS": "YES",
        "LD_RUNPATH_SEARCH_PATHS": "$(inherited) @executable_path/Frameworks"
    }
    for level, settings in [("project", project_settings), ("target", target_settings)]:
        for config in ["Debug", "Release"]:
            chosen = dict(settings)
            if config == "Debug":
                chosen.update({"SWIFT_OPTIMIZATION_LEVEL": "-Onone", "DEBUG_INFORMATION_FORMAT": "dwarf", "ENABLE_TESTABILITY": "YES", "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) DEBUG", "ONLY_ACTIVE_ARCH": "YES"})
            else:
                chosen.update({"SWIFT_OPTIMIZATION_LEVEL": "-O", "SWIFT_COMPILATION_MODE": "wholemodule", "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym"})
            body = " ".join(f"{key} = {quoted(value)};" for key, value in chosen.items())
            obj(f"{level}-{config}", f"isa = XCBuildConfiguration; buildSettings = {{ {body} }}; name = {config};")
        obj(f"{level}-config-list", "isa = XCConfigurationList; buildConfigurations = " + ids([f"{level}-Debug", f"{level}-Release"]) + " defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;")

    obj("project", f"isa = PBXProject; attributes = {{ BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 1600; TargetAttributes = {{ {uid('target')} = {{ CreatedOnToolsVersion = 16.0; }}; }}; }}; buildConfigurationList = {uid('project-config-list')}; compatibilityVersion = \"Xcode 14.0\"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base); mainGroup = {uid('main-group')}; productRefGroup = {uid('products')}; projectDirPath = \"\"; projectRoot = \"\"; targets = " + ids(["target"]))

    PROJECT.mkdir(exist_ok=True)
    (PROJECT / "project.pbxproj").write_text("// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {};\n\tobjectVersion = 56;\n\tobjects = {\n" + "\n".join(objects) + f"\n\t}};\n\trootObject = {uid('project')};\n}}\n")
    scheme_dir = PROJECT / "xcshareddata/xcschemes"
    scheme_dir.mkdir(parents=True, exist_ok=True)
    reference = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid("target")}" BuildableName="CallSignal.app" BlueprintName="CallSignal" ReferencedContainer="container:CallSignal.xcodeproj"/>'
    (scheme_dir / "CallSignal.xcscheme").write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
    <BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{reference}</BuildActionEntry></BuildActionEntries>
  </BuildAction>
  <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables/></TestAction>
  <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
    <BuildableProductRunnable runnableDebuggingMode="0">{reference}</BuildableProductRunnable>
  </LaunchAction>
  <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{reference}</BuildableProductRunnable></ProfileAction>
  <AnalyzeAction buildConfiguration="Debug"/>
  <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''')
    workspace = PROJECT / "project.xcworkspace"
    workspace.mkdir(exist_ok=True)
    (workspace / "contents.xcworkspacedata").write_text('<?xml version="1.0" encoding="UTF-8"?>\n<Workspace version="1.0"><FileRef location="self:"/></Workspace>\n')
    print(f"Generated Xcode project with {len(sources)} Swift sources and {len(resources)} resources.")


if __name__ == "__main__":
    generate()
