/**
 * src/project.vala
 * Copyright (C) 2012, Linus Seelinger <S.Linus@gmx.de>
 *
 * Valama is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Valama is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

using Vala;
using GLib;
using Gee;
using Xml;

public class valama_project{
    public valama_project(string project_file){

        this.project_file = project_file;

        var proj_file = File.new_for_path (project_file);
        project_path = proj_file.get_parent().get_path();
        project_name = proj_file.get_basename();

        guanako_project = new Guanako.project();

        var directory = File.new_for_path (project_path + "/src");

        var enumerator = directory.enumerate_children (FileAttribute.STANDARD_NAME, 0);

        SourceFile[] sf = new SourceFile[0];
        FileInfo file_info;
        while ((file_info = enumerator.next_file ()) != null) {
            string file = project_path + "/src/" + file_info.get_name ();
            if (file.has_suffix(".vala")){
                stdout.printf(@"Found file $file\n");
                var source_file = new SourceFile (guanako_project.code_context, SourceFileType.SOURCE, file);
                guanako_project.add_source_file (source_file);
                sf += source_file;
            }
        }
        source_files = sf;

        load_project_file();

        guanako_project.update();
    }

    public SourceFile[] source_files;
    public Guanako.project guanako_project;
    string project_path;
    string project_file;
    string project_name;

    public string build(){
        string ret;
        GLib.Process.spawn_command_line_sync("sh -c 'cd " + project_path + " && mkdir -p build && cd build && cmake .. && make'", null, out ret);
        return ret;
    }

    void load_project_file (){
        Xml.Doc* doc = Xml.Parser.parse_file(project_file);

        if (doc == null) {
            stdout.printf (@"Cannot read file >$project_file<\n");
            delete doc;
        }

        Xml.Node* root_node = doc->get_root_element ();
        if (root_node == null) {
            stdout.printf (@"The file >$project_file< is empty\n");
            delete doc;
        }

        var packages = new string[0];
        for (Xml.Node* i = root_node->children; i != null; i = i->next) {
            if (i->type != ElementType.ELEMENT_NODE) {
                continue;
            }
            if (i->name == "packages"){
                for (Xml.Node* p = i->children; p != null; p = p->next) {
                    if (p->name == "package")
                        packages += p->get_content();
                }
            }
        }
        guanako_project.add_packages(packages);

        delete doc;
    }
    public void save (){
        var writer = new TextWriter.filename(project_file);
        writer.set_indent (true);
        writer.set_indent_string ("\t");

        writer.start_element("project");
        writer.start_element("packages");
        foreach (string pkg in guanako_project.packages)
            writer.write_element("package", pkg);
        writer.end_element();
        writer.end_element();
    }
}
