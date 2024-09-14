require 'msf/core'  #导入重要的库文件,如同C语言的include和python的import
class MetasploitModule < Msf::Auxiliary #定义这个类的类型,这里指定该模块为msf的auxiliary类
 def initialize(info = {}) #initialize是ruby的一个标准初始化方法 ,调用前通过def声明
   super(             #调用父类(super()能够调用父类的的同名函数,但是不传入任何参数)
     update_info(                #定义模块相关信息
       info,
       'Name'        => 'Sample Auxiliary Module',
       # The description can be multiple lines, but does not preserve formatting.
       'Description' => 'Sample Auxiliary Module',
       'Author'      => ['Joe Module <joem@example.com>'],
       'License'     => MSF_LICENSE,
       'Actions'     => [
         [ 'Default Action' ],
         [ 'Another Action' ]
       ]
     )
   )
 end                                         #结束initialize声明
 def run                                    #定义run函数的内容
   print_status("Running the simple auxiliary module with action #{action.name}") 
   #打印当前action名称 print_status是msf的print_line的一个方法。
 end                      #结束run
end                        #结束class
