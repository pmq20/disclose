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

          char *tmp_prefix;
          char md5_path[256];

          void get_tmp_prefix() {
            tmp_prefix = getenv("TMPDIR");
            if (NULL != tmp_prefix) return;
            tmp_prefix = getenv("TMP");
            if (NULL != tmp_prefix) return;
            tmp_prefix = getenv("TEMP");
            if (NULL != tmp_prefix) return;
            tmp_prefix = getcwd(NULL);
          }

          void untar() {
            char cmd[256] = {0};
            char file[256] = {0};
            char dir[256] = {0};
            FILE *fp = NULL;
            int ret;

            snprintf(file, 255, "%s/disclose.file.XXXXXX", tmp_prefix);
            snprintf(dir, 255, "%s/disclose.dir.XXXXXX", tmp_prefix);

            mktemp(file);
            mkdtemp(dir);

            fp = fopen(file, "wb");
            assert(fp);
            fwrite(tar_tar, sizeof(unsigned char), sizeof(tar_tar), fp);
            fclose(fp);

            #{Gem.win_platform? ? tar_windows : tar}

            rename(dir, md5_path);
          }

          int main(int argc, char const *argv[]) {
            char **argv2 = NULL;
            int i, index;
            struct stat info;
            char arg0[256] = {0};
            char arg1[256] = {0};

            get_tmp_prefix();
            snprintf(md5_path, 255, "%s/disclose.#{md5}", tmp_prefix);

            if( stat( md5_path, &info ) != 0 )
                untar();

            assert(0 == stat( md5_path, &info ) && info.st_mode & S_IFDIR);

            argv2 = malloc(sizeof(char*) * (argc + 10));
            assert(argv2);

            snprintf(arg0, 255, "%s/node", md5_path);
            snprintf(arg1, 255, "%s/#{name}", md5_path);

            argv2[0] = arg0;
            argv2[1] = arg1;
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
