#!/usr/bin/env python3
"""Regenerates DailyPhilosophy.xcodeproj/project.pbxproj. Only needed if you add or remove source files."""
import hashlib,os
def uid(n): return hashlib.md5(n.encode()).hexdigest()[:24].upper()
NAME='DailyPhilosophy'
sources=['DailyPhilosophyApp.swift','ContentView.swift','WebView.swift','Keychain.swift','Store.swift','ClaudeClient.swift','Updater.swift']
res=[('Resources/index.html','index.html','text.html'),('Resources/version.json','version.json','text.json'),('Assets.xcassets','Assets.xcassets','folder.assetcatalog')]
O=[]
def obj(i,body): O.append('\t\t%s = %s;'%(i,body))
fref={};bf={}
for f in sources:
    fref[f]=uid('fref'+f);bf[f]=uid('bf'+f)
    obj(fref[f],'{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = %s; sourceTree = "<group>"; }'%f)
    obj(bf[f],'{isa = PBXBuildFile; fileRef = %s; }'%fref[f])
for path,nm,typ in res:
    fref[nm]=uid('fref'+nm);bf[nm]=uid('bf'+nm)
    obj(fref[nm],'{isa = PBXFileReference; lastKnownFileType = %s; path = "%s"; sourceTree = "<group>"; }'%(typ,path if typ!='text.html' else path))
    obj(bf[nm],'{isa = PBXBuildFile; fileRef = %s; }'%fref[nm])
prod=uid('product');obj(prod,'{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = %s.app; sourceTree = BUILT_PRODUCTS_DIR; }'%NAME)
# groups
g_main=uid('gmain');g_app=uid('gapp');g_prod=uid('gprod')
kids=','.join(fref[f]+' /* %s */'%f for f in sources+['index.html','version.json','Assets.xcassets'])
obj(g_app,'{isa = PBXGroup; children = (%s); path = %s; sourceTree = "<group>"; }'%(kids,NAME))
obj(g_prod,'{isa = PBXGroup; children = (%s); name = Products; sourceTree = "<group>"; }'%prod)
obj(g_main,'{isa = PBXGroup; children = (%s, %s); sourceTree = "<group>"; }'%(g_app,g_prod))
# phases
ph_src=uid('phsrc');ph_res=uid('phres');ph_fw=uid('phfw')
obj(ph_src,'{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (%s); runOnlyForDeploymentPostprocessing = 0; }'%','.join(bf[f] for f in sources))
obj(ph_res,'{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (%s); runOnlyForDeploymentPostprocessing = 0; }'%','.join(bf[n] for n in ['index.html','version.json','Assets.xcassets']))
obj(ph_fw,'{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }')
# configs
def cfg(i,name,settings):
    body='; '.join('%s = %s'%(k,v) for k,v in settings)
    obj(i,'{isa = XCBuildConfiguration; buildSettings = {%s; }; name = %s; }'%(body,name))
common=[('ALWAYS_SEARCH_USER_PATHS','NO'),('CLANG_ENABLE_MODULES','YES'),('CLANG_ENABLE_OBJC_ARC','YES'),('COPY_PHASE_STRIP','NO'),('ENABLE_STRICT_OBJC_MSGSEND','YES'),('GCC_NO_COMMON_BLOCKS','YES'),('IPHONEOS_DEPLOYMENT_TARGET','16.0'),('SDKROOT','iphoneos'),('MTL_FAST_MATH','YES')]
pd=uid('pcfgd');pr=uid('pcfgr');td=uid('tcfgd');tr=uid('tcfgr')
cfg(pd,'Debug',common+[('DEBUG_INFORMATION_FORMAT','dwarf'),('ENABLE_TESTABILITY','YES'),('GCC_OPTIMIZATION_LEVEL','0'),('ONLY_ACTIVE_ARCH','YES'),('SWIFT_ACTIVE_COMPILATION_CONDITIONS','DEBUG'),('SWIFT_OPTIMIZATION_LEVEL','"-Onone"')])
cfg(pr,'Release',common+[('DEBUG_INFORMATION_FORMAT','"dwarf-with-dsym"'),('ENABLE_NS_ASSERTIONS','NO'),('SWIFT_COMPILATION_MODE','wholemodule'),('VALIDATE_PRODUCT','YES')])
tset=[('ASSETCATALOG_COMPILER_APPICON_NAME','AppIcon'),('ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME','AccentColor'),('CODE_SIGN_STYLE','Automatic'),('CURRENT_PROJECT_VERSION','1'),('GENERATE_INFOPLIST_FILE','YES'),
 ('INFOPLIST_KEY_CFBundleDisplayName','"Daily Philosophy"'),('INFOPLIST_KEY_UIApplicationSceneManifest_Generation','YES'),('INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents','YES'),('INFOPLIST_KEY_UILaunchScreen_Generation','YES'),
 ('INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone','UIInterfaceOrientationPortrait'),('LD_RUNPATH_SEARCH_PATHS','("$(inherited)", "@executable_path/Frameworks")'),('MARKETING_VERSION','1.0'),
 ('PRODUCT_BUNDLE_IDENTIFIER','com.jesuscardonavilla.dailyphilosophy'),('PRODUCT_NAME','"$(TARGET_NAME)"'),('SWIFT_EMIT_LOC_STRINGS','YES'),('SWIFT_VERSION','5.0'),('TARGETED_DEVICE_FAMILY','1')]
cfg(td,'Debug',tset);cfg(tr,'Release',tset)
pl=uid('pcfglist');tl=uid('tcfglist')
obj(pl,'{isa = XCConfigurationList; buildConfigurations = (%s, %s); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }'%(pd,pr))
obj(tl,'{isa = XCConfigurationList; buildConfigurations = (%s, %s); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }'%(td,tr))
tgt=uid('target');proj=uid('project')
obj(tgt,'{isa = PBXNativeTarget; buildConfigurationList = %s; buildPhases = (%s, %s, %s); buildRules = (); dependencies = (); name = %s; productName = %s; productReference = %s; productType = "com.apple.product-type.application"; }'%(tl,ph_src,ph_fw,ph_res,NAME,NAME,prod))
obj(proj,'{isa = PBXProject; attributes = {BuildIndependentTargetsInParallel = 1; LastSwiftUpdateCheck = 1500; LastUpgradeCheck = 1500; }; buildConfigurationList = %s; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base); mainGroup = %s; productRefGroup = %s; projectDirPath = ""; projectRoot = ""; targets = (%s); }'%(pl,g_main,g_prod,tgt))
out='// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {\n\t};\n\tobjectVersion = 56;\n\tobjects = {\n'+'\n'.join(O)+'\n\t};\n\trootObject = %s;\n}\n'%proj
os.makedirs('DailyPhilosophy.xcodeproj',exist_ok=True)
open('DailyPhilosophy.xcodeproj/project.pbxproj','w').write(out)
print('wrote',len(O),'objects')
