#! /bin/sh

# Usage:
#   $1:  the number you want to change (default -1, it mean increase 1 for versionCode). If you provide a number greater than  -1, the script will increase versionCode to the number has provided.
#   $2:  allow push code or not, values: true/false
#   $3:  branch to push (require)
#   $4:  allow create and push the tag

#   example1: sh change_version_code.sh -1 true Test true -> increase 1 for versionCode, allow push code to the Test branch, allow push tag
#   example2: sh change_version_code.sh 10 false Test true -> increase versionCode to 10, prevent push code to the Test branch, allow push tag

#  By default for Jenkins job:
#    sh change_version_code.sh -1 true master true-> increase 1 for versionCode, create the tag, push code and tag to the master branch


echo "=========Change build version========="
dir=`pwd`

fileBuild=$(echo ${dir})/app/build.gradle

versionNumberInput=$1
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

        oldVersionCode=${versionCodeNumber}

        versionCodeNumber=`expr ${versionCodeNumber} + 1`

        if [[ ${versionNumberInput} -gt 0 ]]; then

            versionCodeNumber=${versionNumberInput}

        fi

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

oldVersion=${major}.${minor}.${patch}.${oldVersionCode}
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