function hfun_bar(vname)
    val = Meta.parse(vname[1])
    return round(sqrt(val), digits=2)
end

function hfun_m1fill(vname)
    var = vname[1]
    return pagevar("index", var)
end

function lx_baz(com, _)
    # keep this first line
    brace_content = Franklin.content(com.braces[1]) # input string
    # do whatever you want here
    return uppercase(brace_content)
end

"""
    {{menu_items_list}}

Generate an appropriate list of menu items
"""
function hfun_menu_items_list()::String
    io = IOBuffer()
    nav_items = collect(globvar("menubar_items"))
    for i in 1:length(nav_items)
        (title, url) = nav_items[i]
        if i > 1
            write(io, "        ")
        end
        if length(url) <= 1
                url = "/"
        else
                url = "/" * url * "/"
        end
        write(io, "<li class=\"menu-list-item {{ispage $title/*}}active{{end}}\"><a href=\"$url\" class=\"menu-list-link {{ispage $title}}active{{end}}\"> $title</a>")
        if i < length(nav_items)
                write(io, "\n")
        end
    end
    return String(take!(io))
end
