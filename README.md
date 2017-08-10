# RWUIControls
创建自己的framework库，旋转视图以及丝带视图，具体详情可见http://www.cocoachina.com/ios/20150127/11022.html

（原文：How to Create a Framework for iOS 作者：Sam Davies 译者：Mr_cyz ）

在上一篇教程(中译版)中，你学到了怎么样创建一个可复用的圆形旋钮控件。然而你可能不清楚怎样让其他开发者更方便地去复用它。

如果你想将你开发的控件与别人分享，一种方法是直接提供源代码文件。然而，这种方法并不是很优雅。它会暴露所有的实现细节，而这些实现你可能并不想开源出来。此外，开发者也可能并不想看到你的所有代码，因为他们可能仅仅希望将你的这份漂亮代码的一部分植入自己的应用中。

另一种方法是将你的代码编译成静态库（library），让其他开发者添加到自己的项目中。然而，这需要你一并公布所有的公开的头文件，实在是非常不方便。

你需要一种简单的方法来编译你的代码，这种方法应该使得你的代码易分享，并且在多个工程中易复用。你需要的是一种方法来打包你的静态库，将所有的头文件放到一个单元中，这样你就可以立刻将其加入到你的项目中并使用。

非常幸运，这正是本篇教程所要解决的问题。你将会学到制作并使用Framework，帮助你解决这个头疼的问题。OS X完美地支持这一点，因为Xcode就提供了一个项目模板，包含着默认构建目标（target）和可以容纳类似于图片、声音、字体等资源的文件。你可以为iOS创建Framework，不过这是一个比较复杂的手工活，如果你跟着教程走，你将学到怎么样跨过路障，顺利地完成Framework的创建。

当你跟着这篇教程走完后，你将能够：

使用Xcode构建一个基本的静态库工程。
依赖于该静态库工程构建一款应用。
掌握如何将静态库工程转换为完整的、合格的Framework。
最终，你将看到如何将一个图像文件同Framework一起打包到resource bundle下。
开始

这篇教程的主要目的是解释怎么样在你的iOS工程中创建并使用一个Framework。所以，不像其他网站上的教程，这篇教程将只使用一小部分Objective-C代码，并且这一小部分主要是为了说明我们将会遇到的一些概念。

从这里下载可用的资源文件RWKnobControl。如果你在Creating a Static Library Project 这篇文章中完成了创建第一个项目的过程，这里你将会看到怎么样使用去它们。

在创建本工程时，你将要创建的所有的代码和项目文件都可以在Github上找到。对于本篇教程中每个创建阶段都有不同的commit。

什么是Framework？

Framework是资源的集合，将静态库和其头文件包含到一个结构中，让Xcode可以方便地把它纳入到你的项目中。

在OS X上，可能会创建一个动态连接（Dynamically Linked）的framework。通过动态连接，framework可以更新，不需要应用重新连接。在运行时，库中代码的一份拷贝被分享出来，整个工程都可以使用它，因此，这样减少了内存消耗，提高了系统的性能。正如你看到的，这是一个功能强大的特性。

在iOS上，你不能用这种方式添加为系统添加自定义的framework，因此仅有的动态链接的framework只能是Apple提供的那些。（编者注：在iOS 8中已加入此特性，开发者可以使用第三方的动态框架）

然而，这并不意味着framework对于iOS而言是无关紧要的，静态连接的framework依然可以打包代码，使其在不同的应用中复用。

由于framework本质上是静态库的“一站式采购点”，因此在本篇教程中你所做的第一件事就是创建并使用静态库。当跟着教程走到如何创建framework时，你就能明白你所做的一切了，整体思路也不会那么烟雾缭绕了。

创建一个静态库工程

打开Xcode，点击File\New\Project，选择iOS\Framework and Library\Cocoa Touch Static Library新建一个静态库工程.

ios_framework_creating_static_lib-700x482.png

将工程命名为RWUIControls，然后将工程保存到一个空目录下。

ios_framework_options_for_static_lib-700x476.png

一个静态库工程由头文件和实现文件组成，这些文件将被编译为库本身。

为了方便其他开发者使用你的库和framework，你将进行一些操作，让他们仅需要导入一个头文件便可以访问所有你想公开的类。

当创建静态库工程时，Xcode会自动添加RWUIControls.h和RWUIControls.m。你不需要实现文件，因此右键单击RWUIControls.m选择delete，将它删除到废纸篓中。

打开RWUIControls.h，将所有内容替换为：

1
#import < UIKit/UIKit.h>
导入UIKit的头文件，这是创建一个库所需要的。当你在创建不同的组成类时，你将会将它们添加到这个文件中，确保它们能够被库的使用者获取到。

你所构建的项目依赖于UIKit，然而Xcode的静态库工程不会自动连接到UIKit。要解决这个问题，就要将UIKit作为依赖库添加到工程中。在工程导航栏中选择工程名，然后在中央面板中选择RWUIControls目标。

点击BuildPhases，展开Link Binary with Libraries这一部分，点击+添加一个新的framework，找到UIKit.framework，点击add添加进来。

ios_framework_add_uikit_dependency.gif

如果不结合头文件，静态库是没有用的，静态库编译一组文件，在这些文件中类和方法都以二进制数据的形式存在。在你创建的库中，有些类将能够被公开访问到，有些类只能由库内部访问并使用。

接下来，你需要在build栏中添加新的phase，来包含所有头文件，并将它们放到编译器可以获取到的某个地方。然后，你将会拷贝这些到你的framework中。

依然是在Xcode的Build Phases界面，选择Editor\Add Build Phase\Add Copy Headers Build Phase。

Note：如果你发现按上面找到的菜单项是灰色的（不可点击的），点击下方Build Phases界面的白色区域来获取Xcode的应用焦点，然后重新试一下。

ios_framework_add_copy_headers_build_phase.gif

把RWUIControls.h从项目导航栏中拖到中央面板的Copy Headers下的Public部分。这一步确保任何使用你的库的用户均可以获取该头文件。

ios_framework_add_header_to_public.gif

Note：显然，所有包含在你的公共头文件中的头文件必须是对外公开的，这一点非常重要。否则，开发者在使用你的库时会得到编译错误。如果Xcode在读取公共头文件时不能读到你忘记设为public的头文件，这实在是太令人沮丧了。

创建一个UI控件

既然你已经设置好你的工程了，是时候为你的库添加一些功能了。由于本篇教程的关键在于教你怎么样创建一个framework，而不是怎么样构建一个UI控件，这里你将使用上一篇教程中创建好的控件。在你之前下载好的压缩包文件中找到RWKnobControl目录，从Finder中拖到Xcode下RWUIControls目录下。

ios_framework_drop_rwuiknobcontrol_from_finder-700x466.png

选择Copy items into destination group’s folder，点击下方的选择框，确保RWUIControls静态库目标被选中。

ios_framework_import_settings_for_rwknobcontrol-700x475.png

这一步默认把实现文件添加到编译列表，把头文件添加到Project组。这意味着它们目前是私有的。

ios_framework_default_header_membership-700x327.png

Note：在你弄清楚之前，这三个组的名称可能会让你迷惑，Public是你期望的，Private下的头文件依然是可以暴露出来的，因此名字可能有些误导。讽刺的是，在Project下的头文件对你的工程来说才是“私有”的，因此，你将会更多地希望你的头文件或者在Public下，或者在Project下。

现在，你需要将控件的头文件RWKnobControl.h分享出来，有几种方式可以实现这一点，首先是在Copy Headers面板中将这个头文件从Project栏拖到Public栏。

ios_framework_drag_header_to_public.gif

或者，你可能会发现，更简单的方法是，编辑文件，改变Target Membership面板下的membership。这个选项更方便一些，可以让你不断添加文件，扩充你的库。

ios_framework_header_membership-407x320.png

Note：如果你不断往库中添加新的类，记得及时更新这些类的关系（membership），使尽可能少的类成为public，并确保其他非public的头文件都在Project下。

对你的控件的头文件需要做的另一件事是将其添加到库的主头文件RWControls.h中。在这个主头文件的帮助下，开发者使用你的库仅仅需要导入一个头文件，如下面的代码一样，而不是自己去选择自己需要的一块导入。

1
#import < RWUIControls/RWUIControls.h>
因此，在RWUIControls.h中添加下面的代码：

1
2
// Knob Control
#import
配置Build Settings

现在距离构建这个项目、创建静态库已经非常接近了。不过，这里要先进行一些配置，让我们的库对于用户来说更友好。

首先，你需要提供一个目录名，表示你将把拷贝的公共头文件存放到哪里。这样确保当你使用静态库的时候可以定位到相关头文件的位置。

在项目导航栏中点击项目名，然后选择RWUIControls静态库目标，选择Build Setting栏，然后搜索public header，双击Public Headers Folder Path，在弹出视图中键入如图所示内容：

ios_framework_public_headers_path-700x174.png

一会你就会看到这个目录了。

现在你需要改变一些其他的设置，尤其是那些在二进制库中遗留下的设置，编译器提供给你一个选项，来消除无效代码：永远不会被执行的代码。当然你也可以移除掉一些debug用符号，例如某些函数名称或者其他跟debug相关的细节。

因为你正在创建framework供他人使用，最好禁掉这些功能（无效代码和debug用符号），让用户自己选择对自己的项目有利的部分使用。和之前一样，使用搜索框，改变下述设置：

Dead Code Stripping设置为NO
Strip Debug Symbol During Copy 全部设置为NO
Strip Style设置为Non-Global Symbols
编译然后运行，到目前为止没什么可看的，不过确保项目可以成功构建，没有错误和警报是非常好的。

选择目标为iOS Device，按下command + B进行编译，一旦成功，工程导航栏中Product目录下libRWUIControls.a文件将从红色变为黑色，表明现在该文件已经存在了。右键单击libRWUIControls.a，选择Show in Finder。

ios_framework_successful_first_build-700x454.png

再此目录下，你将看到静态库，libRWUIControls.a，以及其他你为头文件指定的目录。注意到，正如你所期望的，那些定为public的头文件可以在此看到。

创建一个依赖开发（Dependent Development）工程

在无法看到真实效果的情况下为iOS开发一个UI控件库是极其困难的，而这是我们现在面临的问题。

没有人期望你闭着眼睛开发出一个UI控件，因此在这一部分你将创建一个新的Xcode工程，该工程依赖于你刚刚创建好的库。这意味着允许你使用示例app创建一个framework。当然，这部分代码将和库本身完全分离，结构会非常清晰。

选择File\Close Project关闭之前的静态库工程，使用File\New\Project创建一个新的工程，选择iOS\Application\Single View Application，将新工程命名为UIControlDevApp，将类前缀命名为RW，选择该工程只支持iPhone，最后将项目保存到和之前的RWUIControls相同的目录下。

添加RWUIControls依赖库，将RWUIControls.xcodeproj从Finder中拖到Xcode中UIControlDevApp组下。

ios_framework_import_library_into_dev_app-700x357.png

现在你可以在你的工程中导航到库工程了，这样做非常好，因为这样意味着你可以在库中编辑代码，并且运行示例工程来测试你做的改变。

Note：你无法将同一工程在两个Xcode窗口中同时打开，如果你发现你无法在你的工程中导航到库工程的话，检查一下是否库工程在其他Xcode窗口中打开了。

这里你可以拷贝代码，而不是和上一个教程似的重新创建代码。首先，选择Main.storyboard, RWViewController.h 和 RWViewController.m，然后右键单击，选择Delete，将它们删除到废纸篓中。然后，将你之前下载的压缩文件中DevApp文件夹拷贝到Xcode的UIControlDevApp组下。

ios_framework_adding_files_to_dev_app.gif

现在，你将添加静态库作为实例项目的依赖库：

在项目导航栏中选择UIControlDevApp。
导航到UIControlDevApp目标下Build Phases面板下。
打开Target Dependencies面板，点击+按钮调出选择器。
找到RWUIControls静态库，选择并点击Add。这一步表明当构建dev应用时，Xcode会检查是否静态库需要重新构建。
为了连接到静态库本身，展开Link Binary With Libraries面板，再次点击+按钮，从Workspace组中选择libRWUIControls.a然后点击Add。

这一步确保Xcode可以连接到静态库，就像连接到系统framework（例如UIKit）一样。

ios_framework_add_dependencies_to_dev_app.gif

编译并运行，如果你按照之前的教程创建了一个旋钮控件，在你眼前展示的将是与之相同的应用。

ios_framework_dev_app_buildrun1-333x500.png

像这样使用嵌套工程的好处是你可以对库本身做出修改，而不用离开示例工程，即使你同时改变两个地方的代码也一样。每次你编译工程，你都要检查是否将头文件的public/project关系设置正确。如果实例工程中缺失了任何需要的头文件，它都不能被编译。

创建一个Framework

到现在，你可能迫不及待地点着脚趾头，想着什么时候framework可以出来。可以理解，因为到现在为止你已经做了许多工作，然而却没有看到过framework的身影。

现在该有所改变了，你之所以到现在都没有创建一个framework，是因为framework本身就是静态库加上一组头文件——实际上正是你已经创建好的东西。

当然，framework也有几点不同之处：

目录结构。Framework有一个能被Xcode识别的特殊的目录结构，你将会创建一个build task，由它来为你创建这种结构。
片段（Slice）。目前为止，当你构建库时，仅仅考虑到当前需要的结构（architecture）。例如，i386、arm7等，为了让一个framework更有用，对于每一个运行framework的结构，该framework都需要构建这种结构。一会你就会创建一个新的工程，构建所有需要的结构，并将它们包含到framework中。
这一部分非常神奇，不过我们会慢慢地来。实际上它并不像看起来那样复杂。

Framework结构

正如之前提到的，一个framework有一个特殊的目录结构，看起来像是这样的：

ios_framework_directory_structure-449x320.png

现在你需要在静态库构建过程中添加脚本来创建这种结构，在项目导航栏中选择RWUIControls，然后选择RWUIControls静态库目标，选择Build Phases栏，然后选择Editor/Add Build Phase/Add Run Script Build Phase来添加一个新的脚本。

ios_framework_framework_add_run_script_build_phase-700x271.png

这一步在build phases部分添加了一个新的面板，这允许你在构建时运行一个Bash脚本。你希望让脚本在build的过程中何时执行，就把这个面板拖动到列表中相对应的那一位置。对于该framework工程来说，脚本最后执行，因此你可以让它保留在默认的位置即可。

ios_framework_new_run_script_build_phase-700x299.png

双击面板标题栏Run Script，重命名为Build Framework。

ios_framework_rename_script-700x131.png

在脚本文本框中粘贴下面的Bash脚本代码
set -e
  
export FRAMEWORK_LOCN="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.framework"
  
# Create the path to the real Headers die
mkdir -p "${FRAMEWORK_LOCN}/Versions/A/Headers"
  
# Create the required symlinks
/bin/ln -sfh A "${FRAMEWORK_LOCN}/Versions/Current"
/bin/ln -sfh Versions/Current/Headers "${FRAMEWORK_LOCN}/Headers"
/bin/ln -sfh "Versions/Current/${PRODUCT_NAME}" \
             "${FRAMEWORK_LOCN}/${PRODUCT_NAME}"
  
# Copy the public headers into the framework
/bin/cp -a "${TARGET_BUILD_DIR}/${PUBLIC_HEADERS_FOLDER_PATH}/" \
           "${FRAMEWORK_LOCN}/Versions/A/Headers"
这个脚本首先创建了RWUIControls.framework/Versions/A/Headers目录，然后创建了一个framework所需要的三个连接符号（symbolic links）。

Versions/Current => A
Headers => Versions/Current/Headers
RWUIControls => Versions/Current/RWUIControls
最后，将公共头文件从你之前定义的公共头文件路径拷贝到Versions/A/Headers目录下，-a参数确保修饰次数作为拷贝的一部分不会改变，防止不必要的重新编译。

现在，选择RWUIControls静态库scheme，然后选择iOS Device构建目标，然后使用cmd+B构建。

ios_framework_build_target_static_lib.png

在RWUIControls工程里Products目录下右键单击libRWUIControls.a静态库，然后再一次选择Show in Finder。

ios_framework_static_lib_view_in_finder-480x295.png

在这次构建目录中你可以看到RWUIControls.framework，可以确定一下这里展示了正确的目录结构：

ios_framework_created_framework_directory_structure-480x251.png

这算是在完成你的framework的过程中迈出了一大步。不过你会注意到这里并没有一个静态lib文件。这就是我们下一步将要解决的问题。

多架构（Multi-Architecture）编译

iOS app需要在许多不同的CPU架构下运行：

arm7: 在最老的支持iOS7的设备上使用
arm7s: 在iPhone5和5C上使用
arm64: 运行于iPhone5S的64位 ARM 处理器 上
i386: 32位模拟器上使用
x86_64: 64为模拟器上使用
每个CPU架构都需要不同的二进制数据，当你编译一个应用时，无论你目前正在使用那种架构，Xcode都会正确地依照对应的架构编译。例如，如果你想跑在虚拟机上，Xcode只会编译i386版本（或者是64位机的x86_64版本）。

这意味着编译会尽可能快地进行，当你归档一款app或者构建app的发布版本（release mode）时，Xcode会构建上述三个用于真机的ARM架构。因此这样app就可以跑在所有设备上了。不过，其他的编译架构又如何呢？

当你创建你的framework时，你自然会想让所有开发者都能在所有可能的架构上运行它，不是吗？你当然想，因为这样可以从同行那儿得到尊敬与赞美。

因此你需要让Xcode在所有架构下都进行编译。这一过程实际上是创建了二进制FAT（File Allocation Table，文件配置表），它包含了所有架构的片段（slice）。

Note：这里实际上强调了创建依赖静态库的示例项目的另一个原因：库仅仅在示例项目运行所需要的架构下编译，只有当有变化的时候才重新编译，为什么这一点会让人激动？因为开发周期会尽可能地缩短。

这里将使用在RWUIControls工程中的一个新的目标来构建framework，在项目导航栏中选择RWUIControls，然后点击已经存在的目标下面的Add Target按钮。

ios_framework_add_target_button-471x320.png

找到iOS/Other/Aggregate，点击Next，将目标命名为Framework。

Note：为什么使用集合（Aggregate）目标来创建一个framework呢？为什么这么不直接？因为OS X对库的支持更好一些，事实上，Xcode直接为每一个OS X工程提供一个Cocoa Framework编译目标。基于此，你将使用集合编译目标，作为Bash脚本的连接串来创建神奇的framework目录结构。你是不是开始觉得这里的方法有些愚蠢了？

为了确保每当这个新的framework目标被创建时，静态链接库都会被编译，你需要往静态库目标中添加依赖（Dependency）。在库工程中选择Framework目标，在Build Phases中添加一个依赖。展开Target Dependencies面板，点击 + 按钮选择RWUIControls静态库。

ios_framework_add_dependency_to_framework_target.gif

这个目标的主要编译部分是多平台编译，你将使用一个脚本来做到这一点。和你之前做的一样，在Framework目标下，选择Build Phases栏，点击Editor/Add Build Phase/Add Run Script Build Phase，创建一个新的Run Script Build Phase。

ios_framework_framework_add_run_script_build_phase-700x271.png

双击Run Script，重命名脚本的名字。这次命名为MultiPlatform Build。

在脚本文本框中粘贴下面的Bash脚本代码：
set -e
  
# If we're already inside this script then die
if [ -n "$RW_MULTIPLATFORM_BUILD_IN_PROGRESS" ]; then
  exit 0
fi
export RW_MULTIPLATFORM_BUILD_IN_PROGRESS=1
  
RW_FRAMEWORK_NAME=${PROJECT_NAME}
RW_INPUT_STATIC_LIB="lib${PROJECT_NAME}.a"
RW_FRAMEWORK_LOCATION="${BUILT_PRODUCTS_DIR}/${RW_FRAMEWORK_NAME}.framework"
set –e确保脚本的任何地方执行失败，则整个脚本都执行失败。这样可以避免让你创建一个部分有效的framework。
接着，用RW_MULTIPLATFORM_BUILD_IN_PROGRESS变量决定是否循环调用脚本，如果有该变量，则退出。
然后设定一些变量。该framework的名字与项目的名字一样。也就是RWUIControls，另外，静态lib的名字是libRWUIControls.a。
接下来，用脚本设置一些函数，这些函数一会项目就会用到，把下面的代码加到脚本的底部。
function build_static_library {
    # Will rebuild the static library as specified
    #     build_static_library sdk
    xcrun xcodebuild -project "${PROJECT_FILE_PATH}" \
                     -target "${TARGET_NAME}" \
                     -configuration "${CONFIGURATION}" \
                     -sdk "${1}" \
                     ONLY_ACTIVE_ARCH=NO \
                     BUILD_DIR="${BUILD_DIR}" \
                     OBJROOT="${OBJROOT}" \
                     BUILD_ROOT="${BUILD_ROOT}" \
                     SYMROOT="${SYMROOT}" $ACTION
}
  
function make_fat_library {
    # Will smash 2 static libs together
    #     make_fat_library in1 in2 out
    xcrun lipo -create "${1}" "${2}" -output "${3}"
}
build_static_library把SDK作为参数，例如iPhone7.0，然后创建静态lib，大多数参数直接传到当前的构建工作中来，不同的是设置ONLY_ACTIVE_ARCH来确保为当前SDK构建所有的结构。
make_fat_library使用lipo将两个静态库合并为一个，其参数为两个静态库和结果的输出位置。从这里了解更多关于lipo的知识。
为了使用这两个方法，接下来脚本将定义更多你要用到的变量，你需要知道其他SDK是什么，例如，iphoneos7.0应该对应iphonesimulator7.0，反过来也一样。你也需要找到该SDK对应的编译目录。

把下面的代码添加到脚本的底部。
# 1 - Extract the platform (iphoneos/iphonesimulator) from the SDK name
if [[ "$SDK_NAME" =~ ([A-Za-z]+) ]]; then
  RW_SDK_PLATFORM=${BASH_REMATCH[1]}
else
  echo "Could not find platform name from SDK_NAME: $SDK_NAME"
  exit 1
fi
  
# 2 - Extract the version from the SDK
if [[ "$SDK_NAME" =~ ([0-9]+.*$) ]]; then
  RW_SDK_VERSION=${BASH_REMATCH[1]}
else
  echo "Could not find sdk version from SDK_NAME: $SDK_NAME"
  exit 1
fi
  
# 3 - Determine the other platform
if [ "$RW_SDK_PLATFORM" == "iphoneos" ]; then
  RW_OTHER_PLATFORM=iphonesimulator
else
  RW_OTHER_PLATFORM=iphoneos
fi
  
# 4 - Find the build directory
if [[ "$BUILT_PRODUCTS_DIR" =~ (.*)$RW_SDK_PLATFORM$ ]]; then
  RW_OTHER_BUILT_PRODUCTS_DIR="${BASH_REMATCH[1]}${RW_OTHER_PLATFORM}"
else
  echo "Could not find other platform build directory."
  exit 1
fi
上面四句声明都非常相似，都是使用字符串比较和正则表达式来确定RW_OTHER_PLATFORM和RW_OTHER_BUILT_PRODUCTS_DIR。

详细解释一下上面四句声明：

SDK_NAME将指代iphoneos7.0和iphonesimulator6.1，这个正则表达式取出字符串开头不包含数字的那些字符，因此，其结果是iphoneos 或 iphonesimulator。
这个正则表达式取出SDK_NAME中表示版本用的数字，7.0或6.1等。
这里用简单的字符串比较来将iphonesimulator 转换为iphoneos，反过来也一样。
从构建好的工程的目录路径的末尾找出平台名称，将其替换为其他平台。这样可以确保为其他平台构建的目录可以被找到。这是将两个静态库合并的关键部分。
现在你可以启动脚本为其他平台编译，然后得到合并两静态库的结果。

在脚本最后添加下面的代码：
# Build the other platform.
build_static_library "${RW_OTHER_PLATFORM}${RW_SDK_VERSION}"
  
# If we're currently building for iphonesimulator, then need to rebuild
#   to ensure that we get both i386 and x86_64
if [ "$RW_SDK_PLATFORM" == "iphonesimulator" ]; then
    build_static_library "${SDK_NAME}"
fi
  
# Join the 2 static libs into 1 and push into the .framework
make_fat_library "${BUILT_PRODUCTS_DIR}/${RW_INPUT_STATIC_LIB}" \
                 "${RW_OTHER_BUILT_PRODUCTS_DIR}/${RW_INPUT_STATIC_LIB}" \
                 "${RW_FRAMEWORK_LOCATION}/Versions/A/${RW_FRAMEWORK_NAME}"
首先，调用你之前定义好的函数为其他平台编译
如果你现在正在为模拟器编译，那么Xcode会默认只在该系统对应的结构下编译，例如i386 或 x86_64。为了在这两个结构下都进行编译，这里调用了build_static_library，基于iphonesimulator SDK重新编译，确保这两个结构都进行了编译。
最后调用make_fat_library将在当前编译目录下的静态lib同在其他目录下地lib合并，依次实现支持多结构的FAT静态库。这个被放到了framework中。
脚本的最后是简单的拷贝命令，将下面代码添加到脚本最后：
# Ensure that the framework is present in both platform's build directories
cp -a "${RW_FRAMEWORK_LOCATION}/Versions/A/${RW_FRAMEWORK_NAME}" \
      "${RW_OTHER_BUILT_PRODUCTS_DIR}/${RW_FRAMEWORK_NAME}.framework/Versions/A/${RW_FRAMEWORK_NAME}"
  
# Copy the framework to the user's desktop
ditto "${RW_FRAMEWORK_LOCATION}" "${HOME}/Desktop/${RW_FRAMEWORK_NAME}.framework"
第一条命令确保framework在所有平台的编译目录中都存在。
第二条将完成的framework拷贝到用户的桌面上，这一步是可选的，但我发现这样做可以很方便的存取framework。
选择Framework集合方案（aggregate scheme），按下cmd+B编译该framework。

ios_framework_select_framework_aggregate_scheme-480x135.png

这一步将构建并在你的桌面上存放一个RWUIControls.framework。

ios_framework_built_framework_on_desktop-700x319.png

为了检查一下我们的多平台编译真的成功了，启动终端，导航到桌面上的framework，像下面一样：

1
2
$ cd ~/Desktop/RWUIControls.framework
$ RWUIControls.framework  xcrun lipo -info RWUIControls
第一条指令导航到framework中，第二行使用lipo指令从RWUIControls静态库中得到需要的信息，这将列出存在于该库中的所有片段。

ios_framework_architectures_in_fat_library-700x257.png

这里你可以看到，一共有五种片段：i386, x86_64, arm7, arm7s 和 arm64，正如你在编译时设定的那样。如果你之前使用lipo –info指令，你可以看到这些片段的一个分组。

如何使用Framework？

OK，你已经有了framework，你也有了库。它们可以提供一种优雅的方法来解决你迄今为止还没有遇到过的问题，但是做这些的意义是什么呢？

使用framework的其中一个主要的优点是简化使用，现在你将创建一个简单的iOS应用，并使用你刚刚创建好的RWUIControls.framework。

使用Xcode创建一个新工程，选择File/New/Project，然后选择iOS/Application/Single View Application，将新工程命名为ImageViewer，设置为仅仅用于iPhone，将其保存到与之前两个工程同样的目录下。这个应用将展示一张图片，允许用户使用RWKnobControl旋转图片。

在你之前下载的压缩文件中找到ImageViewer目录，这里面只有一个图片文件，把这个图片文件sampleImage.jpg从Finder中拖到Xcode的ImageViewer组中。

ios_framework_drag_sample_image_into_xcode-480x299.png

选中Copy items into destination group’s folder，点击Finish完成导入操作。

导入一个framework的步骤几乎相同，将RWUIControls.framework从桌面拖到Xcode中的Frameworks组下。同样，确保选中了Copy items into destination group’s folder。

ios_framework_import_framework.gif

打开RWViewController.m，将里面的代码替换为下面的代码：
#import "RWViewController.h"
#import < RWUIControls/RWUIControls.h>
  
@interface RWViewController ()
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) RWKnobControl *rotationKnob;
@end
  
@implementation RWViewController
  
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Create UIImageView
    CGRect frame = self.view.bounds;
    frame.size.height *= 2/3.0;
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectInset(frame, 0, 20)];
    self.imageView.image = [UIImage imageNamed:@"sampleImage.jpg"];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.imageView];
  
    // Create RWKnobControl
    frame.origin.y += frame.size.height;
    frame.size.height /= 2;
    frame.size.width  = frame.size.height;
    self.rotationKnob = [[RWKnobControl alloc] initWithFrame:CGRectInset(frame, 10, 10)];
    CGPoint center = self.rotationKnob.center;
    center.x = CGRectGetMidX(self.view.bounds);
    self.rotationKnob.center = center;
    [self.view addSubview:self.rotationKnob];
  
    // Set up config on RWKnobControl
    self.rotationKnob.minimumValue = -M_PI_4;
    self.rotationKnob.maximumValue = M_PI_4;
    [self.rotationKnob addTarget:self
                          action:@selector(rotationAngleChanged:)
                forControlEvents:UIControlEventValueChanged];
}
  
- (void)rotationAngleChanged:(id)sender
{
    self.imageView.transform = CGAffineTransformMakeRotation(self.rotationKnob.value);
}
  
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}
  
@end
这就是一个简单的视图控制器，它做了以下几件事：

使用#import导入框架的头文件
设置了一组私有属性来持有UIImageView和RWKnobControl。
创建一个UIImageView，将其放到合适的位置。
为Knob control设置一些属性，包括添加值改变的事件监听器。相应方法为rotationAngleChanged:方法。
rotationAngleChanged:方法简单更新了UIImageView的transform属性，让图片随着knob control的移动而旋转。
具体怎么样使用RWKnobControl，可以看一下上一篇教程，那里解释了怎么样去创建它。

编译并运行，你就能看到一款简单的应用，当你改变knob control的值时图片就会旋转。

ios_framework_image_viewer_rotating.gif

打包（Bundle）资源

你有没有注意到RWUIControls的framework只包含了代码和头文件，其他的文件却没有被包含。例如，你没有使用其他任何资源，比如图片。这是iOS的一个限制，framework只能包含头文件和静态库。

现在准备好，这篇教程要开始进阶了。这一部分你将学到怎么样通过使用bundle整合资源，让其可以随着framework一起发布，进而突破这一限制。

你将创建一个新的UI控件——丝带控件，作为RWUIControls库的一部分。这个控件将在一个UIView的右上方展示一个丝带图片。

创建一个Bundle

资源都会被添加到bundle中，这将是RWUIControls工程上的另一个目标。

打开UIControlDevApp工程，选择RWUIControls子工程，点击Add Target按钮，导航到OS X/Framework and Library/Bundle。将新的Bundle命名为RWUIControlsResources，然后从framework选择框中选择Core Foundation。

ios_framework_import_framework.gif

这里需要配置几个编译设置，因为你正在创建一个在iOS上使用的bundle，这与默认的OS X不同。选择RWUIControlsResources目标，然后点击Build Settings栏，搜索base sdk，选择Base SDK这一行，按下delete键，这一步将OS X切换为iOS。

ios_framework_bundle_set_base_sdk-700x161.png

同时你需要将工程名称改为RWUIControls。搜索product name，双击进入编辑模式，将${TARGET_NAME}替换为RWUIControls。

ios_framework_bundle_set_product_name-700x206.png

默认情况下，有两种resolutions的图片可以产生一些有趣的现象。例如，当你导入一个retina @2x版本的图片时，普通版的和Retina版的将会合并成一个多resolution的TIFF（标签图像文件格式，Tagged Image File Format）。这不是一件好事。搜索hidpi将COMBINE_HIDPI_IMAGES设置为NO。

ios_framework_bundle_hidpi_images-700x234.png

现在，你将确保当你编译framework时，bundle也能被编译并将framework作为依赖添加到集体目标中。选中Framework目标，选择Build Phases栏，展开Target Dependencies面板，点击 + 按钮，选择RWUIControlsResources目标将其添加为依赖。

ios_framework_add_bundle_as_framework_dependency.gif

现在，在Framework目标的Build Phases中，打开MultiPlatform Build面板，在脚本的最后添加下述代码：

1
2
3
# Copy the resources bundle to the user's desktop
ditto "${BUILT_PRODUCTS_DIR}/${RW_FRAMEWORK_NAME}.bundle" \
      "${HOME}/Desktop/${RW_FRAMEWORK_NAME}.bundle"
这条指令将拷贝构建好的bundle到用户的桌面上。现在，编译framework scheme，你会发现bundle在桌面上出现。

ios_framework_bundle_on_desktop-198x320.png

导入Bundle

为了用这个新的bundle开发，你需要在示例项目中使用它，这意味着你必须既把它作为依赖添加到工程中，同时作为一个对象拷贝到项目中。

在项目导航栏中，选择UIControlDevApp工程，点击UIControlDevApp目标，展开RWUIControls工程的Product组，把RWUIControls.bundle拖到Copy Bundle Resources面板中的 Build Phases栏。

在Target Dependencies面板中，点击+按钮，添加新的依赖，然后选择RWUIControlsResources。

ios_framework_add_bundle_for_dev_project.gif

创建一个丝带视图（Ribbon View）

上面的就是所有必需的配置工作了，从你之前下载的压缩文件中将RWRibbon文件夹拖入到RWUIControls工程下RWUIControls组中。

ios_framework_drag_rwribbon-480x309.png

选中Copy the items into the destination group’s folder，在对应的选择框中打勾，确保它被添加到RWUIControls静态lib目标中。

ios_framework_rwribbon_membership-700x472.png

代码中一个很重要的部分是你怎样引用一张图片。如果你看一下RWRibbonView.m文件中的addRibbonView方法，你将会看到相关的这一行代码：

1
UIImage *image = [UIImage imageNamed:@"RWUIControls.bundle/RWRibbon"];
Bundle就像一个文件目录，所以引用bundle中的一张图片是非常简单的。

将图片添加到bundle中，选择这张图片，在右边的面板中，通过选择来表示它应该属于RWUIControlsResources目标。

ios_framework_rwribbon_image_membership-700x208.png

还记得我们说过要确保framework可以被访问吗？现在，你需要导出头文件RWRibbon.h，在Target Membership面板中选择该文件，然后从弹出视图中选择Public。

ios_framework_rwribbon_header_membership-480x262.png

最后，你需要将头文件引用添加到framework的头文件中。打开RWUIControls.h添加下面这两行：

1
2
// RWRibbon
#import < RWUIControls/RWRibbonView.h>
将丝带添加到示例工程中

在UIControlDevApp项目中打开RWViewController.m文件，在@interface后的大括号中添加下面的实例变量声明。

1
RWRibbonView  *_ribbonView;
在viewDidLoad:的末尾添加下面的代码来创建一个丝带视图：
// Creates a sample ribbon view
_ribbonView = [[RWRibbonView alloc] initWithFrame:self.ribbonViewContainer.bounds];
[self.ribbonViewContainer addSubview:_ribbonView];
// Need to check that it actually works :)
UIView *sampleView = [[UIView alloc] initWithFrame:_ribbonView.bounds];
sampleView.backgroundColor = [UIColor lightGrayColor];
[_ribbonView addSubview:sampleView];
编译并运行UIControlDevApp scheme。你将看到新的丝带控件出现在应用的下方。

ios_framework_dev_app_with_ribbon-333x500.png

在ImageViewer中使用Bundle

我要向你分享的最后一件事是怎么样在其他应用中使用这个新的bundle，例如，你之前创建的ImageViewer应用。

开始之前，确保你的bundle和framework都是最新版本的，选择Framework scheme然后按下cmd+B编译。

打开ImageViewer工程，找到Frameworks组中的RWUIControls.framework项目，然后将其删除，选择Move to Trash。然后将RWUIControls.framework从你的桌面上拖到Frameworks组中。这是必须的，因为此时的framework已经与你第一次导入时的framework大不相同了。

ios_framework_delete_framework-700x283.png

Note：如果Xcode拒绝让你添加framework，这可能是因为你并没有真正将之前版本的framework删除到废纸篓。如果是因为这样的话，从Finder中ImageViewer目录下删除framework然后重新尝试。

导入bundle，简单将其从桌面上拖到ImageViewer组中。选中Copy items into destination group’s folder，选中对应的选择框，确保它被添加到ImageViewer目标中。

ios_framework_import_bundle-700x474.png

接下来你要将丝带添加到可以旋转的图片上。因此，在RWViewController.m文件中代码要有一些简单的变动。

打开该文件，将属性imageView的类型从UIImageView变为RWRibbonView：

1
@property (nonatomic, strong) RWRibbonView *imageView;
将viewDidLoad方法中第一部分，负责创建并配置UIImageView的代码，替换为下面的代码：
[super viewDidLoad];
// Create UIImageView
CGRect frame = self.view.bounds;
frame.size.height *= 2/3.0;
self.imageView = [[RWRibbonView alloc] initWithFrame:CGRectInset(frame, 0, 20)];
UIImageView *iv = [[UIImageView alloc] initWithFrame:self.imageView.bounds];
iv.image = [UIImage imageNamed:@"sampleImage.jpg"];
iv.contentMode = UIViewContentModeScaleAspectFit;
[self.imageView addSubview:iv];
[self.view addSubview:self.imageView];
编译并运行该项目，现在该项目中你同时使用了RWUIControls framework下的RWKnobControl和RWRibbonView。

ios_framework_image_viewer_with_ribbon.gif

现在该干什么？

在本篇教程中，你学到了关于创建一个framework并在你的iOS app中使用所需的一切知识，包括开发一个framework的最好的方式，以及怎么样使用bundle来共享资源。

有没有一个你喜欢的功能在多个app中使用了呢？现在你所学到的概念可以帮你创建一个可复用的库，使你的编码更加简单。Framework提供了一种优雅的方式来获得库中的代码，让你在写一个炫酷的app的时候，可以灵活地获取到你需要的一切。

完整工程的源码被放到了Github上，每一步都有一个commit。或者你可以从这里下载完整的压缩文件。
