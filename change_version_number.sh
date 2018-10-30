#! /bin/sh

# Usage:
#   $1: the number you want to change

#   example1: sh changeVersion.sh 1 true master true true -> increase versionCode 1, create tag, push code and tag to branch master
#   example2: sh changeVersion.sh 10 false master true true -> increase versionCode 10, create tag and push tag to branch master


echo "=========Change build version========="
dir=`pwd`

fileBuild=$(echo ${dir})/app/build.gradle

versionNumberInput=$1
isPush=$2
branchPush=$3
isCreateTag=$4
isPushTag=$5

if [[ ${versionNumberInput} == "" ]]; then
    
    echo "You must provide a number to increase versiion"
    exit 1

fi


touch $(echo ${dir})/app/tempbuild.gradle

while IFS= read -r line
do

    flag=`echo ${line}|awk '{print match($0,"versionCode")}'`

    if [ ${flag} -gt 0 ];then
        versionCodeString=$(echo ${line:0:${#line}})
        versionCodeNumber=${versionCodeString:12:`expr ${#versionCodeString} - 12`}

        if [[ ${versionNumberInput} -gt 0 ]]; then

            versionCodeNumber=`expr ${versionCodeNumber} + ${versionNumberInput}`

        fi

        newVersionCodeString=$(echo versionCode ${versionCodeNumber})
        line=${newVersionCodeString}
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

newVersion=${major}.${minor}.${patch}.${versionCodeNumber}

git add app/build.gradle
git commit -m "Increase version to ${newVersion}"

if [[ ${isPush} == "true" ]]; then
    git push origin ${branchPush}
fi


if [[ ${isCreateTag} == "true" ]]; then

    git tag ${newVersion}
    echo "Tag is: ${newVersion}"

    if [[ ${isPushTag} == "true" ]]; then
        git push origin ${newVersion}
    fi

fi

echo "=========Change build version success========="
