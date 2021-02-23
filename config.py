# 数据库信息，一键脚本自动添加
mysql_config = {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': '94imm',
        'USER': '94imm',
        'PASSWORD': '94imm',
        'HOST': '127.0.0.1',
        'PORT': '3306',
    }
# 数组形式，可以添加多个域名
allow_url=["www.94imm.com","94imm.com"]
# 缓存超时时间，服务器性能好可缩短此时
cache_time=300
# 使用的模板（暂时开放一个）
templates="zde"
# 网站名
site_name="94iMM"
# 一键脚本自动添加
site_url = "https://www.94imm.com"
# 网站关键词
key_word = "关键词1,关键词2,关键词3"
# 网站说明
description = "这是一个高质量的自动爬虫"
# 底部联系邮箱
email = "admin@94imm.com"
# 网站调试模式
debug = False
# 友联
friendly_link = [{"name":"94imm","link":"https://www.94imm.com"},{"name":"获取源码","link":"https://github.com/Turnright-git/94imm.git"}]