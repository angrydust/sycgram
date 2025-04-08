import json
import os
import platform
from datetime import datetime
from os import path
from time import time
from typing import Any, Dict, Optional, Tuple

from loguru import logger

from .constants import INSTALL_SPEEDTEST, SPEEDTEST_PATH_FILE, SYCGRAM_ERROR
from .helpers import basher


class Speedtester:
    def __init__(self) -> None:
        pass

    async def __aenter__(self):
        self._timer = time()
        logger.info("Speedtest开始 ...")
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        logger.info(
            f"Speedtest使用了 {time()-self._timer:.5f} 秒结束。")

    async def running(self, cmd: str) -> Tuple[str]:
        """开始执行speedtest

        Args:
            cmd (str, optional): speedtest的完整指令，需要返回json格式.

        Returns:
            Tuple[str]: 第一个值是文本/错误，第二个是图片link
        """
        await self.install_speedtest_cli()
        # 超时报错
        res = await basher(cmd, timeout=60)
        logger.info(f"Speedtest 执行 | {res}")

        try:
            # output result
            self.__output: Dict[str, Any] = json.loads(res.get('output'))
            self.__server: Dict[str, Any] = self.__output.get('server')
        except Exception as e:
            logger.error(e)
            return f"⚠️Speedtest 错误\n```{res.get('error')}```", ''
        else:
            # 如果 error 存在且非空，则返回错误信息
            error = self.__output.get('error')
            if error:
                return f"⚠️Speedtest 错误\n```{error}```", ''
            text = f"**[Speedtest]({self.get_url()})**\n" \
                f"`测速点: {self.get_sponsor()}`\n" \
                f"`本次用量: {self.get_usage()}`\n" \
                f"`上传速度: {self.get_speed('upload')}`\n" \
                f"`下载速度: {self.get_speed('download')}`\n" \
                f"`延迟: `{self.get_ping('latency')} ms \n" \
                f"`CST: {self.get_time()}`\n"
            return text, f"{self.get_url()}.png"

    async def list_servers_ids(self, cmd: str) -> str:
        await self.install_speedtest_cli()
        res = await basher(cmd, timeout=10)
        logger.info(f"Speedtest 执行 | {res}")
        if not res.get('error'):
            try:
                self.__output: Dict[str, Any] = json.loads(res.get('output'))
            except Exception:
                return "**{SYCGRAM_ERROR}**\n> # `⚠️ 无法获取服务器ids`"
            else:
                tmp = '\n'.join(
                    f"`{k.get('id')}` **|** {k.get('name')} **|** {k.get('location')} {k.get('country')}"
                    for k in self.__output.get('servers')
                )
                return f"**Speedtest节点列表：**\n{tmp}"
        return f"**{SYCGRAM_ERROR}**\n```{res.get('error')}```"

    def get_url(self) -> str:
        url = self.__output.get('result').get('url')
        return f"{url}"

    def get_server(self) -> str:
        location = self.__server.get('location')
        return f"`{location}`"

    def get_sponsor(self) -> str:
        return f"`{self.__server.get('name')}`"

    def get_speed(self, opt: str) -> str:
        """
        Args:
            opt (str): upload or download

        Returns:
            str: Convert to bits
        """
        def convert(bits) -> str:
            """Unit conversion"""
            power = 1000
            n = 0
            units = {
                0: 'bps',
                1: 'Kbps',
                2: 'Mbps',
                3: 'Gbps',
                4: 'Tbps'
            }
            while bits > power:
                bits = bits / power
                n = n + 1
            return f"{bits:.2f} {units.get(n)}"
        return f"`{convert(self.__output.get(opt).get('bandwidth')*8)}`"

    def get_usage(self) -> str:
        def convert(bits) -> str:
            power = 1000
            n = 0
            units = {
                0: 'bit',
                1: 'KB',
                2: 'MB',
                3: 'GB',
                4: 'TB'
            }
            while bits > power:
                bits = bits / power
                n = n + 1
            return f"{bits:.2f} {units.get(n)}"
        return f"`{convert(self.__output.get('upload').get('bytes') + self.__output.get('download').get('bytes'))}`"

    def get_ping(self, opt: str) -> str:
        return f"`{self.__output.get('ping').get(opt):.2f}`"

    def get_time(self) -> str:
        return f"`{datetime.strftime(datetime.now(), '%Y-%m-%d %H:%M:%S')}`"

    async def install_speedtest_cli(self, opt: str = 'install') -> Optional[str]:
        def exists_file() -> bool:
            return path.exists(SPEEDTEST_PATH_FILE)

        if platform.uname().system != "Linux" or platform.uname().machine not in [
            'i386', 'x86_64', 'armel', 'armhf', 'aarch64',
        ]:
            text = f"不支持的系统 >>> {platform.uname().system} {platform.uname().machine}"
            logger.warning(text)
            return text
        elif opt == 'install':
            if not exists_file():
                await self.__download_file()
                logger.success("第一次使用安装speedtest")
            return
        elif opt == 'update':
            if exists_file():
                os.remove(SPEEDTEST_PATH_FILE)
            await self.__download_file()
            if exists_file():
                text = "更新speedtest成功。"
                logger.success(text)
                return text
            return "更新speedtest失败！"
        else:
            raise ValueError(f'speedtest选项错误 {opt}！')

    async def __download_file(self) -> None:
        await basher(INSTALL_SPEEDTEST, timeout=30)
