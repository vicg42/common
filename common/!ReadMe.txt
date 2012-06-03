 ак сделать проект:

1.  ¬ыпистать из SVN репозиторий vereskm
2.  пекрейти к каталогу нужной платы (например alpha6T1)

3   запустить core generator и перейти к каталогу core_gen соотв. платы (alpha6T1/ise/src/core_gen) и
    открыть файл проекта.
3.1 перегенерить все модули core_gen.

4.  ¬ каталоге ./ise создать папку prj (alpha6T1/ise/prj)
4.1 запустить скрипт создани€ проекта ISE (alpha6T1/script/make_veresk.bat)

4. скопировать файлы *.ngc, *.coe, *.mif  в каталог  ./ise/prj
   (alpha6T1/ise/src/core_gen *.ngc, *.coe, *.mif   ->   alpha6T1/ise/prj)

5. «апустить ISE, скомпрелировть созданный проект