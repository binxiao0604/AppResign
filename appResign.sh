# SRCROOT 为工程所在目录，Temp 为创建的临时存放 ipa 解压文件的文件夹。
TEMP_PATH="${SRCROOT}/Temp"
# APP 文件夹，存放要重签名的ipa包。
IPA_PATH="${SRCROOT}/IPA"
#重签名 ipa 包路径
TARGRT_IPA_PATH="${IPA_PATH}/*.ipa"

#清空 Temp 文件夹，重新创建目录
rm -rf "$TEMP_PATH"
mkdir -p "$TEMP_PATH"



#1.解压 ipa 包到 Temp 目录下
unzip -oqq "$TARGRT_IPA_PATH" -d "$TEMP_PATH"
#获取解压后临时 App 路径
TEMP_APP_PATH=$(set -- "$TEMP_PATH/Payload/"*.app;echo "$1")
echo "临时App路径：$TEMP_APP_PATH"

#2.将解压出来的 .app 拷贝到工程目录，
# BUILT_PRODUCTS_DIR 工程生成的App包路径
# TARGET_NAME target 名称
TARGET_APP_PATH="$BUILT_PRODUCTS_DIR/$TARGET_NAME.app"
echo "app路径：$TARGET_APP_PATH"

#删除工程自己创建的 app
rm -rf "$TARGET_APP_PATH"
mkdir -p "$TARGET_APP_PATH"
#拷贝解压的临时 Temp 文件到工程目录
cp -rf "$TEMP_APP_PATH/" "$TARGET_APP_PATH"

#3.删除 extension 和 WatchAPP。个人证书无法签名 Extention
rm -rf "$TARGET_APP_PATH/PlugIns"
rm -rf "$TARGET_APP_PATH/Watch"


#4.更新 info.plist 文件 CFBundleIdentifier
# 设置:"Set :KEY Value" "目标文件路径"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $PRODUCT_BUNDLE_IDENTIFIER" "$TARGET_APP_PATH/Info.plist"


#5. macho 文件加上可执行权限。
#获取 macho 文件路径
APP_BINARY=`plutil -convert xml1 -o - $TARGET_APP_PATH/Info.plist|grep -A1 Exec|tail -n1|cut -f2 -d\>|cut -f1 -d\<`
#加上可执行权限
chmod +x "$TARGET_APP_PATH/$APP_BINARY"


#6.重签名第三方 FrameWorks
TARGET_APP_FRAMEWORKS_PATH="$TARGET_APP_PATH/Frameworks"
if [ -d "$TARGET_APP_FRAMEWORKS_PATH" ];
then
for FRAMEWORK in "$TARGET_APP_FRAMEWORKS_PATH/"*
do
#签名
/usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$FRAMEWORK"
done
fi







