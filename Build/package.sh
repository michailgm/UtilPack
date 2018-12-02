#!/bin/sh

# This script is intended to run within Docker container with .NET SDK, and actual command as parameters.
# Therefore all folder names etc are constants.

set -xe
 
# Build IL Generator and XML doc merger
cp /repo-dir/contents/Source/Directory.Build.BuildTargetFolders.props /repo-dir/Directory.Build.props
# Without specifying Configuration, the (intermediate) output paths will be wrong
dotnet build -nologo "/p:Configuration=Release" "/p:TargetFramework=${THIS_TFM}" "/p:BuildCommonOutputDir=/repo-dir/tmpout/" /repo-dir/contents/Build/UtilPackILGenerator

# Invoke IL Generator and XML doc merger
UTILPACK_DIR="/repo-dir/BuildTarget/Release/bin/UtilPack"
dotnet "/repo-dir/tmpout/Release/bin/UtilPackILGenerator/${THIS_TFM}/UtilPackILGenerator.dll" "$UTILPACK_DIR"

# Get the dotnet directory 
DOTNET_DIR=$(dotnet --info | grep Microsoft.NETCore.App | awk '{printf substr($3, 2, length($3)-2); printf "/"; printf $2}')

# Copy il(d)asm to dotnet directory (since libcoreclr.so resides there)
IL_PACKAGES_VERSION=$(cat /repo-dir/contents/ILPackagesVersion.txt)
cp "/root/.nuget/packages/runtime.alpine.3.6-x64.microsoft.netcore.ildasm/${IL_PACKAGES_VERSION}/runtimes/alpine.3.6-x64/native/ildasm" "${DOTNET_DIR}"
cp "/root/.nuget/packages/runtime.alpine.3.6-x64.microsoft.netcore.ilasm/${IL_PACKAGES_VERSION}/runtimes/alpine.3.6-x64/native/ilasm" "${DOTNET_DIR}"

# Disassemble built UtilPack DLL into IL code
find "${UTILPACK_DIR}/" -mindepth 1 -maxdepth 1 -type d -exec "${DOTNET_DIR}/ildasm" \
  "-out={}/UtilPack.il" \
  -utf8 \
  -typelist \
  -all \
  "{}/UtilPack.dll" \;

# Assemble back the IL code from ILDASM and combine it with code generated by UtilPackILGenerator
# Don't use -key here - the ilasm on .NET Core can not sign them (most likely because of legacy C++ code hard-coded to using Windows native crypto-APIs)
find "${UTILPACK_DIR}/" -mindepth 1 -maxdepth 1 -type d -exec "${DOTNET_DIR}/ilasm" \
  -nologo \
  -dll \
  -optimize \
  "-output={}/UtilPack.dll" \
  -highentropyva \
  -quiet \
  "{}/UtilPack.il" \
  "{}/AdditionalIL.il" \;
  
# Check that the IL code actually got into assembly, since find does not return error code if -exec'ed command fails
"${DOTNET_DIR}/ildasm" "-out=/repo-dir/tmpout/UtilPack.il" -utf8 -all "${UTILPACK_DIR}/net40/UtilPack.dll"
grep -q 'UtilPack.DelegateMultiplexer' '/repo-dir/tmpout/UtilPack.il' # This will fail whole script on non-zero return value
  
# Re-sign the assemblies using own tool
# We need to run dotnet build first, since we can't pass MSBuild parameters to dotnet run ( see https://github.com/dotnet/cli/issues/7229 )
dotnet build -nologo "/p:Configuration=Release" "/p:TargetFramework=${THIS_TFM}" "/p:BuildCommonOutputDir=/repo-dir/tmpout/" /repo-dir/contents/CI/StrongNameSigner
find "${UTILPACK_DIR}/" -mindepth 1 -maxdepth 1 -type d -exec dotnet \
  "/repo-dir/tmpout/Release/bin/StrongNameSigner/${THIS_TFM}/StrongNameSigner.dll" \
  "/repo-dir/contents/Keys/UtilPack.snk" \
  "{}/UtilPack.dll" \;
  
# TODO verify here that all assemblies are truly signed, since find does not return error code if -exec'ed command fails

# Package all projects
$@