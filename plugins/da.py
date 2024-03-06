from asyncio import sleep

from pyrogram import Client
from pyrogram.types import Message

from core import command


@Client.on_message(command('da'))
async def da(cli: Client, msg: Message):
    if len(msg.parameter) > 2 or len(msg.parameter) == 0:
        await msg.edit_text("\n呜呜呜，请执行 `-da true` 来删除所有消息。")
        return
    if msg.parameter[0] != "true":
        await msg.edit_text("\n呜呜呜，请执行 `-da true` 来删除所有消息。")
        return
    await msg.edit_text('正在删除所有消息 . . .')
    input_chat = await msg.chat.id
    messages = []
    count = 0
    async for messageid in msg.client.iter_messages(input_chat, min_id=1):
        messages.append(messageid)
        count += 1
        messages.append(1)
        if len(messages) == 100:
            await cli.delete_messages(input_chat, messages)
            messages = []

    if messages:
        await cli.delete_messages(input_chat, messages)
    await msg.reply_text(f"批量删除了 {str(count)} 条消息。")
    try:
        notification = await send_prune_notify(msg, count)
    except:
        return
    await sleep(.5)
    await notification.delete()


async def send_prune_notify(msg, count):
    return await msg.reply_text(
        msg.chat.id,
        "批量删除了 "
        + str(count)
        + " 条消息。"
    )
