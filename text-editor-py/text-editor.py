import tkinter
from tkinter import filedialog

# basic tutorial from:
# https://www.geeksforgeeks.org/build-a-basic-text-editor-using-tkinter-in-python/


# root window
root = tkinter.Tk()

# design of window
root.geometry("1200x800")
root.minsize(height=800)
root.title("Text Edit")

# adding a scrollbar
scrollbar = tkinter.Scrollbar(root)

# packing scrollbar
scrollbar.pack(side=tkinter.RIGHT, fill=tkinter.Y)

# adding text editing window
text_info = tkinter.Text(root, yscrollcommand=scrollbar.set)
text_info.pack(fill=tkinter.BOTH)

# configuring the scrollbar
scrollbar.config(command=text_info.yview)

# configuring the menubar
root.option_add('*tearOff', tkinter.FALSE)

menubar = tkinter.Menu(root)
root['menu'] = menubar

# adding a file menu to menubar
menu_file = tkinter.Menu(menubar)
menubar.add_cascade(menu=menu_file, label="File")

# creating commands for file menu
# newFile =
openFile = filedialog.askopenfile()
# populating file menu with 'new', 'save', 'save as', and 'open' commands
# NEEDS WORK menu_file.add_command(label="New File", command=newFile)
menu_file.add_command(label="Open File", command=openFile)

# execute
root.mainloop()
