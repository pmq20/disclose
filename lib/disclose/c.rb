class Disclose
  module C
    class << self
      def src(f, name, md5)
        windows_prepare(f) if Gem.win_platform?

        f.puts %Q{
          #include <unistd.h>
          #include <stdio.h>
          #include <stdlib.h>
          #include <assert.h>

          void untar() {
            char file[] = "/tmp/disclose.file.XXXXXX";
            char dir[] = "/tmp/disclose.dir.XXXXXX";
            FILE *fp = NULL;
            int ret;

            mktemp(file);
            mkdtemp(dir);

            fp = fopen(file, "wb");
            assert(fp);
            fwrite(tar_tar, sizeof(unsigned char), sizeof(tar_tar), fp);
            fclose(fp);

            #{Gem.win_platform? ? tar_windows : tar}
          }

          int main(int argc, char const *argv[]) {
            char cmd[256] = {0};
            char arg[256] = {0};
            char **argv2 = NULL;
            int i, index;


            snprintf(cmd, 255, "%s/node", dir);
            snprintf(arg, 255, "%s/#{name}", dir);
            argv2 = malloc(sizeof(char*) * (argc + 10));
            assert(argv2);
            argv2[0] = cmd;
            argv2[1] = arg;
            index = 2;
            for (i = 1; i < argc; ++i) {
              argv2[index] = argv[i];
              index += 1;
            }
            argv2[index] = NULL;
            execv(cmd, argv2);

            return 1;
          }
        }
      end
      
      def tar
        %Q{
          snprintf(cmd, 255, "tar xf %s -C %s", file, dir);
          ret = system(cmd);
          assert(0 == ret);
        }
      end
      
      def tar_windows
        %Q{
          char tardir[] = "/tmp/disclose.tardir.XXXXXX";

          ret = chdir(tardir);
          assert(0 == ret);

          fp = fopen("libiconv_2.dll", "wb");
          assert(fp);
          fwrite(libiconv_2_dll, sizeof(unsigned char), sizeof(libiconv_2_dll), fp);
          fclose(fp);

          fp = fopen("libintl_2.dll", "wb");
          assert(fp);
          fwrite(libintl_2_dll, sizeof(unsigned char), sizeof(libintl_2_dll), fp);
          fclose(fp);

          fp = fopen("tar.exe", "wb");
          assert(fp);
          fwrite(tar_exe, sizeof(unsigned char), sizeof(tar_exe), fp);
          fclose(fp);

          snprintf(cmd, 255, "tar xf %s -C %s", file, dir);
          ret = system(cmd);
          assert(0 == ret);
        }
      end
      
      def windows_prepare(f)
        f.puts File.read File.expand_path('../libiconv_2_dll.h', __FILE__)
        f.puts File.read File.expand_path('../libintl_2_dll.h', __FILE__)
        f.puts File.read File.expand_path('../tar_exe.h', __FILE__)
      end
    end
  end
end
