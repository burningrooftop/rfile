'
' RFile - File Manager
' based on FileDrawers (filedrawers.org)
'

PROGRAM$ = "RFile"
VERSION$ = "1.3"

DATEFORMAT$ = "dd/mm/yyyy" ' Display format for dates
TIMEFORMAT$ = "hh:mm" ' Display format for times

global IMAGEURL$
IMAGEURL$ = "/rfile" ' URL to images

dim FAVORITE$(19, 1)
FAVORITE$(0,0) = "Home"     : FAVORITE$(0,1) = DefaultDir$
FAVORITE$(1,0) = "Projects" : FAVORITE$(1,1) = ProjectsRoot$
FAVORITE$(2,0) = "Public"   : FAVORITE$(2,1) = ResourcesRoot$

dim ACTION$(10,1)
ACTION$(0,0) = "Upload File"             : ACTION$(0,1) = "upload"
ACTION$(1,0) = "Create a New File"       : ACTION$(1,1) = "newfile"
ACTION$(2,0) = "Cut Selected Item(s)"    : ACTION$(2,1) = "cut"
ACTION$(3,0) = "Copy Selected Item(s)"   : ACTION$(3,1) = "copy"
ACTION$(4,0) = "Paste to This Folder"    : ACTION$(4,1) = "paste"
ACTION$(5,0) = "Delete Selected Item(s)" : ACTION$(5,1) = "delete"
ACTION$(6,0) = "Create a New Folder"     : ACTION$(6,1) = "new"
ACTION$(7,0) = "Rename Selected Item"    : ACTION$(7,1) = "rename"
ACTION$(8,0) = "Select All Items"        : ACTION$(8,1) = "selectall"
ACTION$(9,0) = "Unselect All Items"      : ACTION$(9,1) = "unselectall"

currentPath$ = DefaultDir$ ' Current path
filenames$ = "" ' Selected file(s)

global pathDelim$ ' Path seperator

if Platform$ = "win32" then
  pathDelim$ = "\"
else
  pathDelim$ = "/"
end if

global IMAGEPATH$
IMAGEPATH$ = ResourcesRoot$ + replaceChar$(IMAGEURL$, "/", pathDelim$)

'
' Load names of all file icons into an array for fast searching
'
files #file, IMAGEPATH$ + pathDelim$ + "mime" + pathDelim$ + "*.gif"

global numIcons
numIcons = #file rowcount()

global ICON$
dim ICON$(numIcons - 1)

for i = 0 to numIcons - 1
  #file nextfile$()
  ICON$(i) = #file name$()
next i

'
' Define copy, cut and delete lists
'
dim copy$(500)
dim cut$(500)
dim delete$(500)

global copy$, numCopies, copySize
global cut$, numCuts, cutSize
global delete$, numDeletes

'
' Define CSS styles
'
cssid #heading, "{background: #000066; color: #FFFFFF; font-family: sans-serif; padding: 2px 8px;}"
cssid #title, "{font-size: large; font-weight: bold;}"
cssid #version, "{float: left;}"
cssid #date, "{text-align: right;}"
cssid #infobar, "{color: #666; border-bottom: 1px solid #369; font-family: sans-serif; padding: 3px;}"
cssid #location, "{}"
cssid #infobuttons, "{float: right;}"
cssid #content, "{font-family: sans-serif; padding: 8px 4px; white-space: normal;}"
cssid #message, "{background: #FFFF99; border: 1px dashed #000000; color: #882222; padding: 10px;}"
cssid #propbox, "{float: left; border: 1px solid #369; padding: 0px; width: 190px;}"
cssid #propheader, "{background: #369; color: #FFFFFF; padding: 4px; font-weight: bold;}"
cssid #propcontent, "{padding: 8px 4px;}"
cssid #selectedfolder, "{background: url(";IMAGEURL$;"/folder.gif); background-repeat: no-repeat; font-weight: bold; line-height: 48px; padding-left: 50px;}"
cssid #selecteditem, "{background: url(";IMAGEURL$;"/doc_lg.gif); background-repeat: no-repeat; font-weight: bold; line-height: 48px; padding-left: 50px;}"
cssid #propsubhead, "{color: #F97909; border-bottom: 1px solid #F97909; font-weight: bold; margin-bottom: 6px;}"
cssid #propmenu, "{margin-left: 4px;}"
cssid #confirm, "{background: #FFFF99; border: 1px dashed #000000; color: #882222; font-family: sans-serif; padding: 10px; margin-left: 15%; margin-right: 20%;}"
cssid #display, "{margin-left: 200px;}"
cssid #info, "{background: #FFFF99; border: 1px dashed #000000; color: #000066; display: block; font-family: sans-serif; padding: 10px; margin-left: 15%; margin-right: 20%;}"
cssid #login, "{background: #F1F1F1; border: 1px solid #69C; color: #000066; display: block; font-family: sans-serif; padding: 10px; margin-left: auto; margin-right: auto; text-align: center; width: 400px;}"
cssid #errormsg, "{color: red; font-weight: bold; padding: 4px 0px; text-decoration: underline;}"
cssclass "table", "{border: 1px solid #69C; border-collapse:collapse; padding: 0px;}"
cssclass "th", "{background: #DEDEEE; color: #369; border: 1px solid #69C; padding: 8px 4px}"
cssclass "td.left0", "{background: #FFFFFF; border: 1px solid #69C; padding: 4px;}"
cssclass "td.left1", "{background: #F1F1F1; border: 1px solid #69C; padding: 4px;}"
cssclass "td.right0", "{background: #FFFFFF; border: 1px solid #69C; padding: 4px; text-align: right;}"
cssclass "td.right1", "{background: #F1F1F1; border: 1px solid #69C; padding: 4px; text-align: right;}"
cssclass "a", "{color: #03C; text-decoration: none;}"
cssclass "a:visted", "{color: #03C; text-decoration: none;}"
cssclass "a:hover", "{color: #03C; text-decoration: underline;}"
cssclass "img", "{border: none;}"
cssclass "div.upload", "{background: #FFFF99; border: 1px dashed #000000; color: #000066; display: block; font-family: sans-serif; padding: 10px; margin-left: 15%; margin-right: 20%;}"

'
' Create the user object
'
run "userObject", #user

'
' Display the Login screen
'
action$ = "login"

'
' Start of main display loop
'
[main]
  on error goto [unexpectedError]

  titlebar PROGRAM$ + " - " + currentPath$

  selectall = 0
  if action$ = "selectall" then selectall = 1

  if action$ = "cut" or action$ = "copy" or action$ = "delete" or action$ = "rename" then
    selected = 0
    rename$ = ""
    for i = 0 to numFiles - 1
      name$ = "check_"; i
      if #name$ value() then
        selected = selected + 1
        select case action$
          case "cut"
            if type$(i) <> "folder" then call cutItem file$(i), size(i)
          case "copy"
            if type$(i) <> "folder" then call copyItem file$(i), size(i)
          case "delete"
            delete$(numDeletes) = file$(i)
            numDeletes = numDeletes + 1
          case "rename"
            rename$ = file$(i)
            call removeCopy file$(i), size(i)
            exit for
        end select
      end if
    next i
    if selected = 0 then
      message$ = "Nothing selected!"
      action$ = ""
    end if
  end if

  if action$ = "delete_item" then action$ = "delete"

  if action$ = "paste" then
    if numCopies = 0 and numCuts = 0 then
      message$ = "Nothing to paste!"
    else
      for i = 0 to numCopies - 1
        source$ = copy$(i)
        target$ = currentPath$ + pathDelim$ + lastItem$(source$, pathDelim$)
        if source$ <> target$ then
          call copyFile source$, target$
        end if
      next i
      numCopies = 0
      copySize = 0

      for i = 0 to numCuts - 1
        source$ = cut$(i)
        target$ = currentPath$ + pathDelim$ + lastItem$(source$, pathDelim$)
        if source$ <> target$ then
          call moveFile source$, target$
        end if
      next i
      numCuts = 0
      cutSize = 0
    end if
  end if

  cls
  div heading
    div title
      print PROGRAM$
    end div
    div version
      print "Version "; VERSION$;
    end div
    div date
      print date$("mmm dd, yyyy"); " "; time$();
    end div
  end div

  select case action$
    case "delete"
      div content
        div confirm
          html "<h2>Comfirm Item Deletion</h2>"
          print
          print "Are you sure that you want to delete the following "; numDeletes; " items(s)?"
          print
          for i = 0 to numDeletes - 1
            print delete$(i)
          next i
          print
          button #delete, "Delete Item(s)", [delete]
          print " ";
          button #cancel, "Cancel", [cancel]
        end div
      end div
    case "login"
      div content
        div login
          html "<h2>";PROGRAM$;" Login</h2>"
          if message$ <> "" then
            div errormsg
              print message$;
              message$ = ""
            end div
          end if
          print "Username: ";
          textbox #username, username$, 20
          #username setfocus()
          print
          print "Password: ";
          passwordbox #password, "", 20
          print
          button #login, "Login", [login]
        end div
      end div
    case "new"
      div content
        div info
          html "<h2>Create a New Folder</h2>"
          print "Folder Name: ";
          textbox #folder, "", 20
          #folder setfocus()
          print " ";
          button #create, "Create Folder", [createFolder]
          print " ";
          button #cancel, "Cancel", [cancel]
        end div
      end div
    case "newfile"
      div content
        div info
          html "<h2>Create a New File</h2>"
          print "File Name: ";
          textbox #filename, "", 20
          #filename setfocus()
          print " ";
          button #create, "Create File", [createFile]
          print " ";
          button #cancel, "Cancel", [cancel]
        end div
      end div
    case "upload"
      html "<div class=""#content"">"
      html "<div class=""upload"">"
      html "<h2>Upload File</h2>"
      print
      link #cancel, "return to folder", [cancel]
      print : print
      upload ""; file$
      if currentPath$ <> DefaultDir$ then
        call moveFile DefaultDir$ + pathDelim$ + file$, currentPath$ + pathDelim$ + file$
      end if
      action$ = ""
      goto [main]
    case else
      div infobar
        div infobuttons
          if action$ = "view" then
            button #goUp, "Go Up", [cancel]
          else
            button #goUp, "Go Up", [goUp]
          end if
          print " ";
          button #refresh, "Refresh", [main]
          print " ";
          button #logout, "Logout", [logout]
        end div
        div location
          print "Location: ";
          if action$ = "change_directory" then
            textbox #newPath, currentPath$, 40
            #newPath setfocus()
            print " ";
            button #go, "Go", [changePath]
            print " ";
            button #cancel, "Cancel", [cancel]
          else
            path$ = ""
            if currentPath$ = "" then
              link #link, "/", [setPath]
              #link setkey("")
            end if
            for i = 1 to countItems(currentPath$, pathDelim$)
              dir$ = myword$(currentPath$, i, pathDelim$)
              if i > 1 then path$ = path$ + pathDelim$
              path$ = path$ + dir$
              if i > 1 then print " > ";
              if dir$ = "" then dir$ = "/"
              link #link, dir$, [setPath]
              #link setkey(path$)
            next i
            if action$ = "view" then print " > "; lastItem$(selectedFile$, pathDelim$);
            print " ";
            button #change, "Change", [action]
            #change setkey("change_directory")
          end if
        end div
      end div
      div content
        div propbox
          if action$ = "view" or action$ = "edit" or action$ = "hexdump" then
            div propheader
              print "Item Properties";
            end div
            div propcontent
              div selecteditem
                print lastItem$(selectedFile$, pathDelim$);
              end div
              div propsubhead
                print "Actions";
              end div
              div propmenu
                if isText(selectedFile$) then
                  link #link, "Edit This Item", [action]
                  #link setkey("edit")
                  print
                end if
                link #link, "Hex Dump This Item", [action]
                #link setkey("hexdump")
                print
                link #link, "Cut This Item", [cutItem]
                print
                link #link, "Copy This Item", [copyItem]
                print
                link #link, "Delete This Item", [deleteItem]
                print
              end div
              print
              div propsubhead
                print "Information";
              end div
              div propmenu
                files #file, selectedFile$
                if #file hasanswer() then
                  #file nextfile$()
                  #file dateformat(DATEFORMAT$)
                  #file timeformat(TIMEFORMAT$)
                  selectedFileSize = #file size()
                  print "Size: "; size$(selectedFileSize)
                  print "Date Modified: "; #file date$()
                  print "Time Modified: "; #file time$()
                end if
              end div
            end div
          else
            div propheader
              print "Folder Properties";
            end div
            div propcontent
              div selectedfolder
                if currentPath$ = "" then
                  print "/"; ' special case for unix root folder
                else
                  print lastItem$(currentPath$, pathDelim$);
                end if
              end div
              div propsubhead
                print "Actions";
              end div
              div propmenu
                i = 0
                while ACTION$(i,0) <> ""
                  link #link, ACTION$(i,0), [action]
                  #link setkey(ACTION$(i,1))
                  print
                  i = i + 1
                wend
              end div
              print
              div propsubhead
                print "Favorites";
              end div
              div propmenu
                i = 0
                while FAVORITE$(i,0) <> ""
                  link #link, FAVORITE$(i,0), [setPath]
                  #link setkey(FAVORITE$(i,1))
                  print
                  i = i + 1
                wend
              end div
              print
              div propsubhead
                print "Information";
              end div
              div propmenu
                if numCopies <> 0 then
                  html "<b>"; numCopies; " item(s) copied</b> ["
                  link #reset, "reset", [resetCopy]
                  print "]"
                  print size$(copySize)
                  for i = 0 to numCopies - 1
                    print lastItem$(copy$(i), pathDelim$)
                  next i
                  print
                end if
                if numCuts <> 0 then
                  html "<b>"; numCuts; " item(s) cut</b> ["
                  link #reset, "reset", [resetCut]
                  print "]"
                  print size$(cutSize)
                  for i = 0 to numCuts - 1
                    print lastItem$(cut$(i), pathDelim$)
                  next i
                  print
                end if
              end div
            end div
          end if
        end div

        div display
        if message$ <> "" then
          div message
            html message$
          end div
          print
          message$ = ""
        end if

        if action$ = "view" or action$ = "edit" or action$ = "hexdump" then
          if action$ = "hexdump" then
            open selectedFile$ for input as #in
            if lof(#in) > 0 then
              a$ = input$(#in, lof(#in))
            else
              a$ = ""
            end if
            close #in
            html "<pre>"
            for i = 0 to len(a$) - 1
              if i mod 16 = 0 then
                if i > 0 then print
                print zeropad$(dechex$(i), 4);
              end if
              print "  ";
              c$ = mid$(a$, i + 1, 1)
              select case asc(c$)
                case 0
                  print "\0";
                case 8
                  print "\b";
                case 9
                  print "\t";
                case 10
                  print "\n";
                case 12
                  print "\f";
                case 13
                  print "\r";
                case else
                  if asc(c$) < 32 then
                    print zeropad$(dechex$(asc(c$)), 2);
                  else
                    print " ";c$;
                  end if
              end select
            next i
            html "</pre>"
          else
            type$ = getFileType$(selectedFile$)
            if type$ = "gif" or type$ = "jpg" or type$ = "jpeg" or type$ = "png" then
              if isDownloadable(selectedFile$) then
                html "<img src=""";downloadURL$(selectedFile$);""">"
              else
                loadgraphic #img, selectedFile$
                render #img
              end if
            else
              if isText(selectedFile$) then
                if action$ = "view" then
                  open selectedFile$ for input as #in
                  if lof(#in) > 0 then
                    html "<pre>"
                    while not(eof(#in))
                      line input #in, a$
                      print a$
                    wend
                    close #in
                    html "</pre>"
                  else
                    div message
                      print "This file is empty."
                    end div
                  end if
                else
                  open selectedFile$ for input as #in
                  if lof(#in) > 0 then
                    a$ = input$(#in, lof(#in))
                  else
                    a$ = ""
                  end if
                  close #in
                  textarea #edit, a$, 80, 30
                  print : print
                  button #cancel, "Cancel", [action]
                  #cancel setkey("view")
                  print " ";
                  button #save, "Save", [saveEdit]
                end if
              else
                div message
                  html"<h2>Unsupported File Type</h2>"
                  print "This file contains binary data and is not viewable in a web browser."
                  print
                  if isDownloadable(selectedFile$) then
                    print "You may ";
                    html "<a href="""; downloadURL$(selectedFile$); """>download <img src=""";IMAGEURL$;"/download.gif""></a>"
                    print " this file, or ";
                  end if
                  link #cancel, "return to the parent folder", [cancel]
                end div
              end if
            end if
          end if
        else
          html "<table>"
          html "<tr>"
          html "<th><img src=""";IMAGEURL$;"/checkbox.gif""></th><th>Type</th><th>Title</th><th><img src=""";IMAGEURL$;"/download.gif""></th><th>Size</th><th>Last Modified</th>"
          html "</tr>"
          files #file, currentPath$ + pathDelim$ + "*"
          numFiles = #file rowcount()
          if numFiles = 0 then
            html "<td class=""row0"" colspan=""6""><i>This folder contains no files or folders.</i></td>"
          else
            ' Build sorted file list
            dim title$(numFiles - 1)
            dim file$(numFiles - 1)
            dim size(numFiles - 1)
            dim type$(numFiles - 1)
            dim lastMod$(numFiles - 1)
            #file dateformat(DATEFORMAT$)
            #file timeformat(TIMEFORMAT$)
            for i = 0 to numFiles - 1
              #file nextfile$()
              for j = 0 to i
                if title$(j) > #file name$() then exit for
              next j
              for k = i to j + 1 step -1
                title$(k) = title$(k - 1)
                type$(k) = type$(k - 1)
                file$(k) = file$(k - 1)
                size(k) = size(k - 1)
                lastMod$(k) = lastMod$(k - 1)
              next k
              title$(j) = #file name$()
              if #file isdir() then
                type$(j) = "folder"
              else
                type$(j) = getFileType$(title$(j))
              end if
              file$(j) = currentPath$ + pathDelim$ + title$(j)
              size(j) = #file size()
              lastMod$(j) = #file date$() + " at " + #file time$()
            next i

            ' Display file list
            k = 0
            for i = 0 to numFiles - 1
              ' Hide "cut" items
              found = 0
              for j = 0 to numCuts - 1
                if cut$(j) = file$(i) then
                  found = 1
                  exit for
                end if
              next j
              if not(found) then
                icon$ = getSmallIcon$(type$(i))
                k = k + 1
                tdWithClass$ = "<td class=""left"; k mod 2; """>"
                tdWithClassRight$ = "<td class=""right"; k mod 2; """>"
                html "<tr>"
                html tdWithClass$
                name$="check_"; i
                checkbox #name$, "", selectall
                html "</td>"
                html tdWithClass$
                if type$(i) = "folder" then
                  imagebutton #link, icon$, [setPath]
                else
                  imagebutton #link, icon$, [view]
                end if
                #link setkey(file$(i))
                html "</td>"
                html tdWithClass$
                if action$ = "rename" and file$(i) = rename$ then
                  textbox #newname, title$(i), 20
                  #newname setfocus()
                  print " ";
                  link #rename, "rename", [rename]
                  print " | ";
                  link #cancel, "cancel", [cancel]
                else
                  if type$(i) = "folder" then
                    link #link, title$(i), [setPath]
                  else
                    link #link, title$(i), [view]
                  end if
                  #link setkey(file$(i))
                end if
                html "</td>"
                html tdWithClass$
                if type$(i) <> "folder" and isDownloadable(file$(i)) then
                  html "<a href=""" + downloadURL$(file$(i)); """><img src=""";IMAGEURL$;"/download.gif""></a>"
                end if
                html "</td>"
                html tdWithClassRight$
                if type$(i) <> "folder" then print size$(size(i));  
                html "</td>"
                html tdWithClass$
                print lastMod$(i);
                html "</td>"
                html "</tr>"            
              end if
            next i
          end if
          html "</table>"
          ' action$ = ""
        end if
        end div
      end div
  end select
  wait
end

[action]
  action$ = EventKey$
  goto [main]

[baddir]
  message$ = "The folder '" + newPath$ + "' does not exist!"
  goto [main]

'
' Generic cancel action - clear the deleted items list and return to the folder display
'
[cancel]
  action$ = ""
  numDeletes = 0
  goto [main]

'
' Change the current folder to the one specified by the user
'
[changePath]
  action$ = ""
  newPath$ = trim$(#newPath contents$())
  while right$(newPath$, 1) = pathDelim$
    newPath$ = left$(newPath$, len(newPath$) - 1)
  wend
  if not(dirExists(newPath$)) then [baddir]
  currentPath$ = newPath$
  goto [main]

'
' Add the curent item to the copy items list
'
[copyItem]
  call copyItem selectedFile$, selectedSize
  goto [main]

'
' Create a new file
'
[createFile]
  filename$ = #filename contents$()
  if filename$ = "" then
    message$ = "No file name supplied!"
    goto [main]
  end if

  if not(validName(filename$)) then
    message$ = "File name contains invalid characters."
    goto [main]
  end if

  selectedFile$ = currentPath$ + pathDelim$ + filename$
  open selectedFile$ for output as #out
  print #out, ""
  close #out
  action$ = "edit"
  goto [main]

'
' Create a new folder
'
[createFolder]
  folder$ = #folder contents$()
  if folder$ = "" then
    message$ = "No folder name supplied!"
    goto [main]
  end if

  if not(validName(folder$)) then
    message$ = "Folder name contains invalid characters."
    goto [main]
  end if

  folder$ = currentPath$ + pathDelim$ + folder$
  if mkdir(folder$) then
    action$ = ""
  else
    message$ = "Cannot create folder '" + folder$ + "'."
  end if
  goto [main]

[cutItem]
  action$ = ""
  call cutItem selectedFile$, selectedSize
  goto [main]

'
' Delete all the items in the delete items list
'
[delete]
  action$ = ""
 
  for i = 0 to numDeletes - 1
    path$ = delete$(i)
    files #file, path$
    if #file hasanswer() then
      #file nextfile$()
      size = #file size()
      if #file isdir() then
        if not(rmdir(path$)) then message$ = message$ + "<br/>Failed to delete folder '" + path$ + "'"
      else
        on error goto [deleteError]
        kill path$
        call removeCopy path$, size
      end if
    end if
  next i
  numDeletes = 0
  if message$ <> "" then message$ = mid$(message$, 6) ' Skip first <br/>
  goto [main]

[deleteError]
  numDeletes = 0
  message$ = mid$(message$, 6) + "<br/>Failed to delete file '" + path$ + "'"
  goto [main]

'
' Add the current item to the delete list
'
[deleteItem]
  action$ = "delete_item"
  delete$(0) = selectedFile$
  numDeletes = 1
  goto [main]

'
' Go to the parent folder
'
[goUp]
  action$ = ""
  newPath$ = myword$(currentPath$, 1, pathDelim$)
  for i = 2 to countItems(currentPath$, pathDelim$) - 1
    newPath$ = newPath$ + pathDelim$ + myword$(currentPath$, i, pathDelim$)
  next i
  currentPath$ = newPath$
  goto [main]

'
' Check login password
'
[login]
  username$ = lower$(#username contents$())
  password$ = #password contents$()

  userId = #user login(username$, password$)

  if userId = 0 then
    message$ = #user errorMessage$()
    goto [main]
  end if

  if username$ <> "ncc" then
    message$ = "You are not authorised to use this program."
    goto [main]
  end if

  action$ = ""
  goto [main]

'
' Logout
'
[logout]
  #user logout()
  expire "/"

'
' Rename an item
'
[rename]
  action$ = ""
  newname$ = #newname contents$()
  if newname$ = "" then
    message$ = "No name supplied!"
    goto [main]
  end if

  if not(validName(newname$)) then
    message$ = "Name contains invalid characters."
    goto [main]
  end if

  if Platform$ = "win32" then
    message$ = shell$("rename " + escapeWin$(rename$) + " " + escapeWin$(newname$))
  else
    newname$ = currentPath$ + pathDelim$ + newname$
    message$ = shell$("mv " + escapeUnix$(rename$) + " " + escapeUnix$(newname$))
  end if
  goto [main]

[resetCopy]
  numCopies = 0
  copySize = 0
  goto [main]

[resetCut]
  numCuts = 0
  cutSize = 0
  goto [main]

[saveEdit]
  a$ = #edit contents$()
  open selectedFile$ for output as #out
  print #out, a$;
  close #out
  action$ = "view"
  goto [main]

[setPath]
  action$ = ""
  currentPath$ = EventKey$
  goto [main]

[unexpectedError]
  if action$ = "view" then
    message$ = "An unexpected error occurred while trying to view '";selectedFile$;"'."
  else
    message$ = "An unexpected error has occurred<br/>Error Number: ";err;"<br/>Error Message: ";err$
  end if
  action$ = ""
  goto [main]

[view]
  action$ = "view"
  selectedFile$ = EventKey$
  goto [main]

'
' Add a file to the cut list
'
sub cutItem name$, size
  for i = 0 to numCuts - 1
    if cut$(i) = name$ then
      found = 1
      exit for
    end if
  next i
  if not(found) then
    cut$(numCuts) = name$
    numCuts = numCuts + 1
    cutSize = cutSize + size
    call removeCopy name$, size
  end if
end sub

'
' Add a file to the copy list
'
sub copyItem name$, size
  for i = 0 to numCopies - 1
    if copy$(i) = name$ then
      found = 1
      exit for
    end if
  next i
  if not(found) then
    copy$(numCopies) = name$
    numCopies = numCopies + 1
    copySize = copySize + size
  end if
end sub

'
' Copy a file from source$ to target$
'
sub copyFile source$, target$
  open source$ for binary as #fin
  if fileExists(target$) then kill target$
  open target$ for binary as #fout
  size = lof(#fin)
  pos = 0
  while pos < size
    r = min(size - pos, 2048)
    x$ = input$(#fin, r)
    print #fout, x$;
    pos = pos + r
  wend
  close #fin
  close #fout
end sub

'
' Copy a file from source$ to target$, then delete source$
'
sub moveFile source$, target$
  call copyFile source$, target$
  kill source$
end sub

'
' Remove a file from the copy list
'
sub removeCopy name$, size
  for i = 0 to numCopies - 1
    if copy$(i) = name$ then
      for j = i + 1 to numCopies - 1
        copy$(j - 1) = copy$(j)
      next j
      numCopies = numCopies - 1
      copySize = copySize - size
      exit for
    end if
  next i
end sub

'
' Return the last item in the list s$ delimted by d$
'
function lastItem$(s$, d$)
  for i = len(s$) to 1 step -1
    if mid$(s$, i, 1) = d$ then exit for
    lastItem$ = mid$(s$, i, 1) + lastItem$
  next i
end function

'
' Return the number if items delimted by d$ in the list s$
'
function countItems(s$, d$)
  if s$ = "" then
    countItems = 0
  else
    countItems = 1
    for i = 1 to len(s$)
      if mid$(s$, i, 1) = d$ then countItems = countItems + 1
    next i
  end if
end function

'
' Test if the directory exists
'
function dirExists(path$)
  files #file, path$
  if #file hasanswer() then
    #file nextfile$()
    if #file isdir() then dirExists = 1
  end if
end function

'
' Quote string for Windows shell
'
function escapeWin$(s$)
  escapeWin$ = """" + s$ + """"
end function

'
' Quote string for Unix Shell
'
function escapeUnix$(s$)
  escapeUnix$ = "'" + replaceChar$(s$, "'", "'""'""'") + "'"
end function

'
' Test if the file exists
'
function fileExists(path$)
  files #file, path$
  if #file hasanswer() then fileExists = 1
end function

'
' Convert the path into a URL
'
function downloadURL$(path$)
  downloadURL$ = mid$(path$, len(ResourcesRoot$) + 1)
  if pathDelim$ <> "/" then
    downloadURL$ = replaceChar$(downloadURL$, pathDelim$, "/")
  end if
end function

'
' Get the file type (extension)
'
function getFileType$(path$)
  name$ = lastItem$(path$, pathDelim$)
  if instr(name$, ".") = 0 then
    getFileType$ = ""
  else
    getFileType$ = lower$(lastItem$(path$, "."))
    if len(getFileType$) > 4 then getFileType$ = ""
  end if
end function

'
' Find the icon corresponding to the file type
'
function getSmallIcon$(type$)
  for i = 0 to numIcons - 1
    if lower$(type$ + ".gif") = lower$(ICON$(i)) then
      getSmallIcon$ = IMAGEURL$ + "/mime/" + ICON$(i)
      exit for
    end if
  next i
  if getSmallIcon$ = "" then
    getSmallIcon$ = IMAGEURL$ + "/mime/empty.gif"
  end if
end function

'
' Test if a file is in the public directory
'
function isDownloadable(path$)
  if left$(path$, len(ResourcesRoot$) + 1) = ResourcesRoot$ + pathDelim$ then isDownloadable = 1
end function

'
' Test is a file appears to be text
'
function isText(path$)
  isText = 1
  open path$ for input as #in
  size = min(lof(#in) - 1, 40)
  a$ = input$(#in, size)
  for i = 1 to len(a$)
    c = asc(mid$(a$, i, 1))
    select case c
      case 9
      case 10
      case 13
      case else
        if c < 32 or c > 126 then
          isText = 0
          exit for
        end if
    end select
  next i
  close #in
end function

'
' Just like word$() but returns any empty string instead
' of the delimiter if a word is missing
'
function myword$(s$, n, d$)
  myword$ = word$(s$, n, d$)
  if myword$ = d$ then myword$ = ""
end function

'
' Replaces all instances of the character c$ in the string s$ with the string r$
'
function replaceChar$(s$, c$, r$)
  for i = 1 to len(s$)
    a$ = mid$(s$, i, 1)
    if a$ = c$ then a$ = r$
    replaceChar$ = replaceChar$ + a$
  next i
end function

'
' Format the size s (in bytes) as Kb
'
function size$(s)
  kb = int((s / 1024) + 0.5)
  if kb = 0 then
    size$ = "< 1 Kb"
  else
    size$ = trim$(using("###,###,###,###", kb)) + " Kb"
  end if
end function

'
' Check that name is a valid file/folder name
'
function validName(name$)
  if instr(name$, pathDelim$) = 0 then
     validName = 1
    if Platform$ = "win32" then
      for i = 1 to len(name$)
        if instr("<>:""/\|?*", mid$(name$, i, 1)) > 0 then
          validName = 0
          exit for
        end if
      next i
      if right$(name$, 1) = "." then validName = 0
    end if
  end if
end function

function zeropad$(s$, n)
  for i = len(s$) to n - 1
    zeropad$ = zeropad$ + "0"
  next i
  zeropad$ = zeropad$ + s$
end function
