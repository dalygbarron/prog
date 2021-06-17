#!/usr/bin/env lua

-- Prog, the Program Progenitor.
-- Copyright (C) 2021 Daly Graham Barron
-- This program is free software: you can redistribute it and/or modify it
-- under the terms of the GNU General Public License version 3 as published
-- by the Free Software Foundation.
-- This program is distributed in the hope that it will be useful, but WITHOUT
-- ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
-- more details.
-- You should have received a copy of the GNU General Public License along
-- with this program.  If not, see <https://www.gnu.org/licenses/>.

local pl = require 'pl.import_into'()
pl.app.require_here()
local query = require 'query'

DESCRIPTION = [[
Program
Progenitor v1.0.0
Copyright (C) Daly Graham Barron 2021
Free Software under the GPL 3 license
 -h, --help shows help
 -I... (string) extra search directory for plugins
 <plugin> (string) Determines the type of project to generate.
 <folder> (string) The folder to create the project in (must be empty or not
                   currently existent).
]]

--- An iteration function that works like next except it also tells you if you
-- are on the last value in the table so you can do special logic then like eg
-- omitting a final comma if writing a list.
-- @param table is the table to iterate over.
-- @param index is the key that we are up to.
-- @return the new index, the value, and a truthy/falsy value for whether or
--         not it is the last value, unless the index is for the last value in
--         which case you just get nil
function iter_ended(table, index)
    local new_index, value = next(table, index)
    if new_index ~= nil then
        return new_index, value, next(table, new_index)
    end
    return nil
end

--- Like pairs but it uses iter_ended instead of next.
-- @param table the table we are iterating over.
-- @return iter_ended function and the passed table.
function pairs_ended(table)
    return iter_ended, table
end

--- Finds the location of a plugin by searching in some places like home.
-- Actually, right now, ~/.prog/pluginname is the only place it looks but it
-- might look in more places in the future. For example penlight provides
-- directories where lua modules should be able to be found or something so
-- I should definitely look there if it will mean these plugins can be
-- installed via luarocks or whatever.
-- @param name is the name of the plugin to find
-- @param search is the list of directories in which to seek the plugin.
-- @return table containing the plugin details or nil and an error message if
--         there is a problem finding it.
function find_plugin(name, search)
    for k, v in ipairs(search) do
        local plugin_dir = pl.path.join(v, name)
        local plugin_info = pl.path.join(plugin_dir, name..'.ini')
        if not (pl.path.exists(plugin_dir) and
            pl.path.exists(plugin_info))
        then
            plugin_dir = pl.path.join(v, 'prog-'..name)
            plugin_info = pl.path.join(plugin_dir, name..'.ini')
        end
        if not (pl.path.exists(plugin_dir) and
            pl.path.exists(plugin_info))
        then
            goto continue
        end
        do
            local result = assert(pl.config.read(plugin_info))
            result.root = plugin_dir
            return result
        end
        ::continue::
    end
    return nil, string.format('plugin %s could not be found', name)
end

--- Reads a version string and returns a table with it's components
-- @param string is the version string to read.
-- @return table with major minor and fix
function read_version(string)
    local major = 0
    local minor = 0
    local fix = 0
    local parts = pl.utils.splitv(string, '.')
    if parts[1] then
        major = assert(tonumber(parts[1]), 'invalid version')
    end
    if parts[2] then
        major = assert(tonumber(parts[2]), 'invalid version')
    end
    if parts[3] then
        major = assert(tonumber(parts[3]), 'invalid version')
    end
end

--- Runs the actual writing of data to the output directory. Can throw errors
-- if anything messes up and does not roll back. Handle that outside.
-- @param plugin is the table of plugin data from the ini file.
-- @param target is the output directory. We assume it exists.
-- @param extra_args is a table that different calls to writing can share. You
--        need to at least pass an empty table.
-- @param search is a list of extra search places if a plugin calls another
function writing(plugin, target, extra_args, search)
    local code = pl.file.read(pl.path.join(
        plugin.root,
        plugin.main
    ))
    if code == nil then
        error(string.format(
            '%s/%s does not exist',
            plugin.root,
            plugin.main
        ))
    end
    local script = assert(load(code, plugin.name, 't', {
        error = error,
        assert = assert,
        pairs = pairs,
        ipairs = ipairs,
        pairs_ended = pairs_ended,
        next = next,
        year = os.date('%Y'),
        stringToTable = pl.pretty.read,
        tableToString = pl.pretty.write,
        dump = pl.pretty.dump,
        tablex = pl.tablex,
        path = pl.path,
        query = query,
        makeFolder = function (...)
            local args = {...}
            for k, v in ipairs(args) do
                local path = pl.path.join(target, v)
                local status, err = pl.dir.makepath(path)
                if not status then return status, err end
            end
            return true
        end,
        copy = function (src, dst)
            local src_path = pl.path.join(plugin.root, src)
            local dst_path = pl.path.join(target, dst)
            if pl.path.isdir(src_path) then
                return pl.dir.clonetree(src_path, dst_path)
            else
                return pl.dir.copyfile(src_path, dst_path)
            end
        end,
        templateFile = function (src, dst, args)
            local content = pl.file.read(pl.path.join(plugin.root, src))
            if content == nil then
                return false, 'no template called '..src
            end
            local result, err = pl.template.substitute(content, args)
            if not result then return false, err end
            pl.file.write(pl.path.join(target, dst), result)
            return true
        end,
        include = function (name, args)
            local included_plugin = assert(find_plugin(name, search))
            writing(included_plugin, target, args, search)
        end
    }))
    script(extra_args)
end

--- Body of the program
-- @param args the commandline arguments parsed
function main(args)
    if not args.I then args.I = {} end
    table.insert(args.I, pl.path.expanduser('.prog'))
    local plugin = assert(find_plugin(args.plugin, args.I))
    local create = false
    if pl.path.exists(args.folder) then
        for f in pl.dir.dirtree(args.folder) do
            error(string.format(
            'folder %s cannot be used as it is not empty',
            args.folder
        ))
        end
    else
        assert(pl.dir.makepath(args.folder))
        create = true
    end
    local status, err = pcall(writing, plugin, args.folder, {}, args.I)
    if not status then
        pl.utils.fprintf(
            io.stderr,
            'Writing failed. Rolling Back. Reason below.\n'
        )
        if create then
            pl.dir.rmtree(args.folder)
        else
            for key, file in ipairs(pl.dir.getallfiles(args.folder)) do
                pl.dir.rmtree(file)
            end
        end
        error(err)
    elseif plugin.message then
        print(plugin.message)
    else
        print('done')
    end
end

local args = pl.lapp(DESCRIPTION)
local status, err = pcall(main, args)
if not status then
    pl.lapp.error(err)
end

