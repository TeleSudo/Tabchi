# [Tabchi](https://telegram.me/LuaError)
* * *

## دستورات سودو

| درباره دستور | دستور |
|:--------|:-------------------------------------------|
| [#!/]pm id text | ارسال پیام به ایدی مورد نظر |
| [#!/]block id | بلاک کردن فرد مورد نظر |
| [#!/]ulock id | انبلاک کردن فرد مور نظر |
| [#!/]markread on/off | روشن و خاموش کردن تیک مارک رید |
| [#!/]setphoto (on reply) | ست کردن پروفایل ربات |
| [#!/]contactlist | دریافت لیست کانتکت ها به صورت فایل تکست |
| [#!/]stats | دریافت وضعیت بوت |
| [#!/]echo text | نوشتن متن توسط ربات |
| [#!/]export links | دادن لینک های ذخیره شده ربات به صورت تکست |
| [#!/]bc text | ارسال متن به همه گروها و شخصی ها |
| [#!/]fwdall (on reply) | فروارد کردن مسیج ریپلای شده به شخصی و گروها |
| $cmd | اجرا کردن دستور در ترمینال |

* * *

# نصب

```sh
# دستورات نصب

#نصب پیش نیازها

sudo apt-get install libreadline-dev libconfig-dev libssl-dev lua5.2 liblua5.2-dev lua-socket lua-sec lua-expat libevent-dev make unzip git redis-server autoconf g++ libjansson-dev libpython-dev expat libexpat1-dev

#کد نصب بوت
cd $HOME
git clone https://github.com/TeleSudo/TTabchi.git
cd TTabchi
git clone --recursive https://github.com/janlou/tg.git
cd tg
./configure && make
cd
cd Tabchi
chmod +x launch.sh
./launch.sh

```

## دستورات اتولانچ
```sh
sudo killall screen
sudo killall tmux
sudo killall telegram-cli
sudo tmux new-session -s script "bash steady.sh -t"
```

## باتشکر
[ITEAM](https://telegram.me/iTeam_ir)

## تهیه شده توسط
[LuaError](https://telegram.me/LuaError)
