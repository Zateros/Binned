using Soup;

namespace Binned{
    class Submitter : Object {
        private Session session;
        private string _server;
        private string? _auth;

        public string server { get { return _server; } set { _server = value; } }
        public string? auth { get { return _auth; } set { _auth = value == "" ? null : value; } }

        construct {
            session = new Session();
        }

        ~Submitter() {
            session.abort();
        }

        public signal void start();
        public signal void end();

        private bool running_already = false;

        public async string send_text_async(string text, string etime, string eunit, bool oneshot) {
            if(!running_already) {
                start();
                running_already = true;
            }
            FileIOStream iostream;
            File tmp = File.new_tmp ("rpaste_send_tmp_XXXXXX.txt", out iostream);
            OutputStream ostream = iostream.output_stream;
            DataOutputStream dstream = new DataOutputStream(ostream);
            dstream.put_string(text);
            dstream.close();
            return yield send_file_async(tmp.get_path(), "text/plain", etime, eunit, oneshot);
        }

        public async string send_url_async(string dest, string etime, string eunit, bool oneshot) {
            if(!running_already) {
                start();
                running_already = true;
            }
            var multipart = new Multipart ("multipart/form-data");

            string header = "";
            if (oneshot) {
                header = "oneshot_url";
            }else {
                if(/^https?:\/\/[\w.-]+(?:\/[\w.-]*)*\/[\w.-]+\.[\w]+$/.match(dest)) {
                    header = "remote";
                }else {
                    header = "url";
                }
            }

            multipart.append_form_string(header, dest);

            Message message = new Message.from_multipart(server, multipart);

            if(auth != null) message.request_headers.append ("Authorization", auth);
            string unit;
            switch (eunit) {
                case "Nanosecond": unit = "ns"; break;
                case "Microsecond": unit = "us"; break;
                case "Milisecond": unit = "ms"; break;
                default: unit = eunit.down(); break;
            }
            if (etime != null && int.parse(etime) > 0) message.request_headers.append ("expire", etime+unit);

            try {
                Bytes response = yield session.send_and_read_async(message, 0, null);
                end();
                running_already = false;
                return (string) response.get_data();
            } catch (Error e) {
                end();
                running_already = false;
                return e.message;
            }
        }

        public async string send_file_async(string path, string mimetype, string etime, string eunit, bool oneshot) {
            if(!running_already) {
                start();
                running_already = true;
            }
            var multipart = new Multipart ("multipart/form-data");

            File file;
            Bytes file_content;
            try {
                file = File.new_for_path(path);
                file_content = file.load_bytes();
            } catch (Error e) {
                end();
                running_already = false;
                return e.message;
            }
            multipart.append_form_file (oneshot ? "oneshot" : "file", path, mimetype, file_content);

            Message message = new Message.from_multipart(server, multipart);
            if(auth != null) message.request_headers.append ("Authorization", auth);
            string unit;
            switch (eunit) {
                case "Nanosecond": unit = "ns"; break;
                case "Microsecond": unit = "us"; break;
                case "Milisecond": unit = "ms"; break;
                default: unit = eunit.down(); break;
            }
            if (etime != null && int.parse(etime) > 0) message.request_headers.append ("expire", etime+unit);

            try {
                Bytes response = yield session.send_and_read_async(message, 0, null);
                end();
                running_already = false;
                return (string) response.get_data();
            } catch (Error e) {
                end();
                running_already = false;
                return e.message;
            }
        }
    }
}
