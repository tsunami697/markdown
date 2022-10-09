#!/bin/sh

set_tools()
{
	sudo apt install vim git exuberant-ctags cscope pip
	pip install googletrans
}

set_bundle()
{
	git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/vundle/
}

set_vimconfig()
{
	cp dotvimrc ~/.vimrc
}

start()
{
	set_tools
	set_bundle
	set_vimconfig
}

start

#上述代码执行后，安装了vundle插件管理工具；
#接着打开vim，输入 :PluginInstall进行安装所有插件
