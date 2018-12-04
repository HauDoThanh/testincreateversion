#! /bin/sh

# Usage:
#   $1: the type for change versionName, it only accept three types:
# + major: increase major, reset minor and patch to 0 - using when we have a big change
# + minor: increase minor, reset patch to 0 - using when release each sprint
# + patch: increase patch - using when release hot-fix

#   $2:  allow push code or not, values: true/false
#   $3:  branch to push, if $2=true, you must provide a branch
#   $4:  allow create tag or not, values: true/false

#   example1: sh change_version_name.sh minor true Test true -> increase minor, allow push code to the Test branch, allow create and push the tag
#   example2: sh change_version_name.sh patch false Test true -> increase patch, prevent push code to the Test branch, allow create and push the tag

#   By default for Jenkins job:
#       sh change_version_name.sh minor true master true -> increase minor, allow push code & tag to the master branch

echo "=========Change build version========="
dir=`pwd`

fileBuild=$(echo ${dir})/app/build.gradle

typeChange=$1
isPush=$2
branchPush=$3
isCreateTag=$4

if [[ ${branchPush} != "" ]]; then

    git checkout ${branchPush} 2>log.txt

    status=`cat log.txt`

    rm log.txt

    if [[ ${status} == *"error"* ]]; then
        echo "The branch name \"${branchPush}\" is not exist, please check again"
        exit 1
    fi

else

    echo "You must provide a branch to push"
    exit 1

fi


touch $(echo ${dir})/app/tempbuild.gradle

while IFS= read -r line
do


    flag=`echo ${line}|awk '{print match($0,"versionCode")}'`

    if [ ${flag} -gt 0 ];then
        versionCodeString=$(echo ${line:0:${#line}})
        versionCodeNumber=${versionCodeString:12:`expr ${#versionCodeString} - 12`}

        newVersionCodeString=$(echo versionCode ${versionCodeNumber})
        line=${newVersionCodeString}
    fi

    
    flag=`echo ${line}|awk '{print match($0,"versionName")}'`

    if [ ${flag} -gt 0 ];then
        versionNameString=$(echo ${line:0:${#line}})

        versionNameNumber=${versionNameString:13:`expr ${#versionNameString} - 14`}

        major=$(echo ${versionNameNumber}| cut -d'.' -f 1)
        minor=$(echo ${versionNameNumber}| cut -d'.' -f 2)
        patch=$(echo ${versionNameNumber}| cut -d'.' -f 3)

        oldVersionName=${major}.${minor}.${patch}

        if [[ ${typeChange} == "minor" ]]; then
            minor=`expr ${minor} + 1`
            patch=0
        fi

        if [[ ${typeChange} == "patch" ]]; then
            patch=`expr ${patch} + 1`
        fi

        if [[ ${typeChange} == "major" ]]; then
            major=`expr ${major} + 1`
            minor=0
            patch=0
        fi

        newVersionNameString=$(echo versionName \"${major}.${minor}.${patch}\")
        line=${newVersionNameString}
    fi

    flag=`echo ${line}|awk '{print match($0,"\"\"\"")}'`

    if [ ${flag} -gt 0 ];then
        replace=\"\"\"
        stringReplace=\"\\\"\"

        line=${line/${replace}/${stringReplace}}
    fi

    flag=`echo ${line}|awk '{print match($0,"\"%s%s/\"\"")}'`

    if [ ${flag} -gt 0 ];then
        replace=\"%s%s/\"\"
        stringReplace=\"%s%s/\\\"\"

        line=${line/${replace}/${stringReplace}}
    fi

    echo ${line} >> $(echo ${dir})/app/tempbuild.gradle

done <"$fileBuild"

cp /dev/null $(echo ${dir})/app/build.gradle
cp $(echo ${dir})/app/tempbuild.gradle $(echo ${dir})/app/build.gradle
rm $(echo ${dir})/app/tempbuild.gradle


echo ${newVersionCodeString}
echo ${newVersionNameString}

oldVersion=${oldVersionName}.${versionCodeNumber}
newVersion=${major}.${minor}.${patch}.${versionCodeNumber}

if [[ ${isCreateTag} == "true" ]]; then

    echo "Tag is: ${oldVersion}"
    git tag ${oldVersion}
    git push origin ${oldVersion}

fi


git add app/build.gradle
git commit -m "Increase version to ${newVersion}"

if [[ ${isPush} == "true" ]]; then
    git push origin ${branchPush}
fi




echo "=========Change build version success========="