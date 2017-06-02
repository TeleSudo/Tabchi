# [Tabchi](https://telegram.me/LuaError)
[![Channel](https://t.me/LuaError)]
* * *

## دستورات سودو

| دستور | درباره دستور |
|:--------|:-------------------------------------------|
|🛑Brodcast Option:|
|🔰!pm [Id] [Text]🔰 |ارسال پیام به ایدی موردنظر|
|🔰!bc [text]🔰| ارسال پیغام همگانی|
|🔰!fwdall {reply on msg}🔰| فوروارد همگانی |
|🛑User Option:|
|🔰!block [Id]🔰| بلاک کردن فرد مورد نظر |
|🔰!unblock [id]🔰| انبلاک کردن فرد مور نظر |
|🛑Contacts Option:|
|🔰!addcontact [phone] [FirstName][LastName]🔰| اضافه کردن یک کانتکت |
|🔰!delcontact [phone] [FirstName][LastName]🔰| حذف کردن یک کانتکت |
|🔰!sendcontact [phone] [FirstName][LastName]🔰| ارسال یک کانتکت |
|🔰!contactlist🔰 | دریافت لیست کانتکت ها |
|🛑Robot Advanced Option:|
|🔰!markread [on]/[off]🔰 | روشن و خاموش کردن تیک مارک رید |
|🔰!setphoto {on reply photo}🔰 | ست کردن پروفایل ربات |
|🔰!stats🔰 | دریافت آمار ربات |
|🔰!addmember🔰 | اضافه کردن کانتکت های ربات به گروه |
|🔰!echo [text]🔰 | برگرداندن نوشته |
|🔰!export link🔰 | دریافت لینک های ذخیره شده |
|🔰!setpm [text]🔰 | تنظیم پیام ادشدن کانتکت |
|🔰!reload🔰| ریلود کردن ربات |
|🔰 $cmd 🔰| اجرا کردن دستور در ترمینال |

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
cd TTabchi
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
