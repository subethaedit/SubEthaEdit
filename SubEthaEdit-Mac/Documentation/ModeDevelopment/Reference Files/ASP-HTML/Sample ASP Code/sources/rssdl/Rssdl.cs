using System;
using System.IO;
using System.Text;
using System.Xml;
using RssToolkit;

namespace Rssdl {

    class Program {
        static void Main(string[] args) {
            Console.WriteLine("Simple RSS Compiler v1.0");
            Console.WriteLine();

            // Process command line
            if (args.Length != 2) {
                Console.WriteLine("usage: rssdl.exe url-or-file outputcode.cs");
                return;
            }

            string url = args[0];
            string codeFilename = args[1];
            string classNamePrefix = Path.GetFileNameWithoutExtension(codeFilename);

            // Load the channel data from supplied url
            GenericRssChannel channel;
            try {
                // try to interpret as file first
                bool isFile = false;

                try {
                    if (File.Exists(url)) {
                        isFile = true;
                    }
                }
                catch {
                }

                if (isFile) {
                    XmlDocument doc = new XmlDocument();
                    doc.Load(url);
                    channel = GenericRssChannel.LoadChannel(doc);
                }
                else {
                    channel = GenericRssChannel.LoadChannel(url);
                }
            }
            catch (Exception e) {
                Console.WriteLine("*** Failed to load '{0}' *** {1}: {2}", url, e.GetType().Name, e.Message);
                return;
            }

            // Open the output code file
            TextWriter codeWriter;
            try {
                codeWriter = new StreamWriter(codeFilename, false);
            }
            catch (Exception e) {
                Console.WriteLine("*** Failed to open '{0}' for writing *** {1}: {2}", codeFilename, e.GetType().Name, e.Message);
                return;
            }

            // Get the language from file extension
            string lang = Path.GetExtension(codeFilename);

            if (lang != null && lang.Length > 1 && lang.StartsWith(".")) {
                lang = lang.Substring(1).ToUpperInvariant();
            }
            else {
                lang = "CS";
            }

            // Generate source
            try {
                RssCodeGenerator.GenerateCode(channel, lang, "", classNamePrefix, codeWriter);
            }
            catch (Exception e) {
                codeWriter.Dispose();
                File.Delete(codeFilename);

                Console.WriteLine("*** Error generating '{0}' *** {1}: {2}", codeFilename, e.GetType().Name, e.Message);
                return;
            }

            // Done
            codeWriter.Dispose();

            Console.WriteLine("Done -- generated '{0}'.", codeFilename);

        }
    }
}
