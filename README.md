# docker-mongo-alpine

## ?

也不知道为什么mongo官方不出alpine版本的docker

其他的都太大了 我们公司项目打包好要2个多G  
网上找到的都不能直接设置用户名密码，也不能执行初始化脚本 就很麻烦啊  
自己就弄了个这 放上来让大家省点事

## Pull
`docker pull ztyhehe/mongo-alpine`


## Build

`docker build -t mongo-alpine .`

> PS:  
alpine:3.8 安装mongo是3.6版本


## 运行

`docker run -p 27017:27017 -v ~/db:/data/db mongo-alpine`  
PS: mongo运行是使用mongodb用户运行的 不要修改映射目录权限不然会起不来 提示目录只读


## 数据库初始化脚本

`/docker-entrypoint-initdb.d`文件夹里面的`.sh`, `.js`文件会被执行


## 用户名、密码

可以通过环境变量`MONGO_INITDB_ROOT_USERNAME`和`MONGO_INITDB_ROOT_PASSWORD`设置  
也可以通过/docker-entrypoint-initdb.d文件夹里的脚本设置

通过环境变量设置账号密码  
用户验证库是admin  `rootAuthDatabase='admin'`  
用户权限是root
