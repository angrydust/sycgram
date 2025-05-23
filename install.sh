#!/bin/bash
clear

CONTAINER_NAME="sycgram"
GITHUB_IMAGE_NAME="angrydust/${CONTAINER_NAME}"
GITHUB_IMAGE_PATH="ghcr.io/${GITHUB_IMAGE_NAME}"
PROJECT_PATH="/opt/${CONTAINER_NAME}"
PROJECT_VERSION="v4.0.0"

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

pre_check() {
    [[ $EUID -ne 0 ]] && echo -e "${red}错误: ${plain} 需要root权限\n" && exit 1

    command -v git >/dev/null 2>&1
    if [[ $? != 0 ]]; then
        echo -e "正在安装Git..."
        apt install git -y >/dev/null 2>&1
        echo -e "${green}Git${plain} 安装成功"
    fi

    command -v curl >/dev/null 2>&1
    if [[ $? != 0 ]]; then
        echo -e "正在安装curl..."
        apt install curl -y >/dev/null 2>&1
        echo -e "${green}curl${plain} 安装成功"
    fi

    command -v docker >/dev/null 2>&1
    if [[ $? != 0 ]]; then
        echo -e "正在安装Docker..."
        bash <(curl -fsL https://get.docker.com) >/dev/null 2>&1
        echo -e "${green}Docker${plain} 安装成功"
    fi

    command -v tar >/dev/null 2>&1
    if [[ $? != 0 ]]; then
        echo -e "正在安装tar..."
        apt install tar -y >/dev/null 2>&1
        echo -e "${green}tar${plain} 安装成功"
    fi
}

delete_old_image_and_container(){
    echo -e "${yellow}正在删除旧版本容器...${plain}"
    docker rm -f $(docker ps -a | grep ${CONTAINER_NAME} | awk '{print $1}')

    echo -e "${yellow}正在删除旧版本镜像...${plain}"
    docker image rm -f $(docker images | grep ${CONTAINER_NAME} | awk '{print $3}')
}

update_command(){
      # 获取最新指令说明
      # 远程file
      remote_file="https://raw.githubusercontent.com/angrydust/sycgram/main/data/command.yml"
      # 本地file
      local_cmd_file="${PROJECT_PATH}/data/command.yml"
      if [[ -f ${local_cmd_file} ]]; then
          t=$(date "+%H_%M_%M")
          mkdir -p "${PROJECT_PATH}/data/command" >/dev/null 2>&1

          echo -e "${yello}正在备份${plain} >>> ${local_cmd_file}"
          cp ${local_cmd_file} "${PROJECT_PATH}/data/command/command.yml.${t}"
      fi
      curl -fsL ${remote_file} > ${local_cmd_file}
}

check_and_create_config(){
if [ ! -f ${PROJECT_PATH}/data/config.ini ]; then

mkdir -p "${PROJECT_PATH}/data" >/dev/null 2>&1

read -p "请输入你的 api_id：" api_id
read -p "请输入你的 api_hash：" api_hash

cat > ${PROJECT_PATH}/data/config.ini <<EOF
[pyrogram]
api_id=${api_id}
api_hash=${api_hash}
[plugins]
root=plugins
EOF
fi
}

stop_sycgram(){
    res=$(docker stop $(docker ps -a | grep ${GITHUB_IMAGE_NAME} | awk '{print $1}'))
    if [[ $res ]];then
        echo -e "${yellow}已停止sycgram...${plain}"
    else
        echo -e "${red}无法停止sycgram...${plain}"
    fi
}

restart_sycgram(){
    res=$(docker restart $(docker ps -a | grep ${GITHUB_IMAGE_NAME} | awk '{print $1}'))
    if [[ $res ]];then
        echo -e "${yellow}已重启sycgram...${plain}"
    else
        echo -e "${red}无法重启sycgram...${plain}"
    fi
}

fish_sycgram(){
    echo -e "${yellow}进入容器中...${plain}"
    docker exec -it ${CONTAINER_NAME} fish
}

view_docker_log(){
    docker logs -f $(docker ps -a | grep ${GITHUB_IMAGE_NAME} | awk '{print $1}')
}

uninstall_sycgram(){
    delete_old_image_and_container;
    rm -rf ${PROJECT_PATH}
    echo -e "已删除${PROJECT_PATH}"
}

reinstall_sycgram(){
    rm -rf ${PROJECT_PATH}
    echo -e "已删除${PROJECT_PATH}"
    install_sycgram
}

install_sycgram(){
    pre_check;
    check_and_create_config;
    update_command;

    echo -e "${yellow}正在拉取镜像...${plain}"
    docker pull ${GITHUB_IMAGE_PATH}:latest

    echo -e "${yellow}正在启动容器...${plain}"
    docker run -it \
    --name ${CONTAINER_NAME} \
    --env TZ="Asia/Shanghai" \
    --restart always \
    --network host \
    --hostname ${CONTAINER_NAME} \
    -v ${PROJECT_PATH}/data:/sycgram/data \
    ${GITHUB_IMAGE_PATH}:latest
}

update_sycgram(){
      delete_old_image_and_container;
      update_command;

      echo -e "${yellow}正在拉取镜像...${plain}"
      docker pull ${GITHUB_IMAGE_PATH}:latest

      echo -e "${yellow}正在启动容器...${plain}"
      docker run -itd \
      --name ${CONTAINER_NAME} \
      --env TZ="Asia/Shanghai" \
      --restart always \
      --network host \
      --hostname ${CONTAINER_NAME} \
      -v ${PROJECT_PATH}/data:/sycgram/data \
      ${GITHUB_IMAGE_PATH}:latest
}

show_menu() {
    echo -e "${green}Sycgram${plain} | ${green}管理脚本${plain} | ${red}${PROJECT_VERSION}${plain}"
    echo -e "  ${green}1.${plain}  安装"
    echo -e "  ${green}2.${plain}  更新"
    echo -e "  ${green}3.${plain}  停止"
    echo -e "  ${green}4.${plain}  重启"
    echo -e "  ${green}5.${plain}  进入容器"
    echo -e "  ${green}6.${plain}  查看日志"
    echo -e "  ${green}7.${plain}  重新安装"
    echo -e "  ${green}8.${plain}  卸载"
    echo -e "  ${green}0.${plain}  退出脚本"
    read -ep "请输入选择 [0-7]: " option
    case "${option}" in
    0)
        exit 0
        ;;
    1)
        install_sycgram
        ;;
    2)
        update_sycgram
        ;;
    3)
        stop_sycgram
        ;;
    4)
        restart_sycgram
        ;;
    5)
        fish_sycgram
        ;;
    6)
        view_docker_log
        ;;
    7)
        reinstall_sycgram
        ;;
    8)
        uninstall_sycgram
        ;;
    *)
        echo -e "${yellow}已退出脚本...${plain}"
        exit
        ;;
    esac
}

show_menu;
