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
          #include <sys/types.h>
          #include <sys/stat.h>

          void untar() {
            char cmd[256] = {0};
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

            rename(dir, "/tmp/disclose.#{md5}");
          }

          int main(int argc, char const *argv[]) {
            char **argv2 = NULL;
            int i, index;
            struct stat info;

            if( stat( "/tmp/disclose.#{md5}", &info ) != 0 )
                untar();

            assert(0 == stat( "/tmp/disclose.#{md5}", &info ) && info.st_mode & S_IFDIR);

            argv2 = malloc(sizeof(char*) * (argc + 10));
            assert(argv2);
            argv2[0] = "/tmp/disclose.#{md5}/node";
            argv2[1] = "/tmp/disclose.#{md5}/#{name}";
            index = 2;
            for (i = 1; i < argc; ++i) {
              argv2[index] = argv[i];
              index += 1;
            }
            argv2[index] = NULL;
            execv(argv2[0], argv2);

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
