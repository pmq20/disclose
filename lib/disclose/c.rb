class Disclose
  module C
    class << self
      def slash
        Gem.win_platform? ? %q{\\\\} : '/'
      end

      def src(f, name, md5, node_name)
        windows_prepare(f) if Gem.win_platform?
        f.puts %Q{
          #{ '#include <io.h>' if Gem.win_platform? }
          #{ '#include <process.h>' if Gem.win_platform? }
          #{ '#include <direct.h>' if Gem.win_platform? }
          #{ '#include <windows.h>' if Gem.win_platform? }
          #include <unistd.h>
          #include <string.h>
          #include <stdio.h>
          #include <stdlib.h>
          #include <assert.h>
          #include <sys/types.h>
          #include <sys/stat.h>
          #include <pthread.h>
          #include <time.h>

          #define PBSTR "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"
          #define PBWIDTH 60

          char *tmp_prefix;
          char md5_path[1024];
          char cwd_path[1024];
          double percentage;

          void printProgress()
          {
              int val = (int) (percentage);
              int lpad = (int) (percentage / 100.0 * PBWIDTH);
              int rpad = PBWIDTH - lpad;
              fprintf(stderr, "\\rExtracting %3d%% [%.*s%*s]", val, lpad, PBSTR, rpad, "");
              fflush(stderr);
          }

          void *progress()
          {
            while (percentage < 100) {
              percentage += (rand() % 188) * 1.0 / 100;
              sleep(1);
              printProgress();
            }
            percentage = 100.0;
            printProgress();
            return NULL;
          }

          void get_tmp_prefix() {
            tmp_prefix = getenv("TMPDIR");
            if (NULL != tmp_prefix) return;
            tmp_prefix = getenv("TMP");
            if (NULL != tmp_prefix) return;
            tmp_prefix = getenv("TEMP");
            if (NULL != tmp_prefix) return;
            tmp_prefix = cwd_path;
          }

          void untar() {
            char cmd[1024] = {0};
            char file0[1024] = {0};
            char file[1024] = {0};
            char dir[1024] = {0};
            FILE *fp = NULL;
            int ret;
            pthread_t thread;

            pthread_create(&thread, NULL, progress, NULL);

            // Be careful about the number of XXXXXX
            // Relate to the magical numbers 23, 20, 19 below.
            snprintf(file0, 1023, "%s#{slash}disclose.file.XXXXXX", tmp_prefix);
            snprintf(dir, 1023, "%s#{slash}disclose.dir.XXXXXX", tmp_prefix);

            mktemp(file0);
            mktemp(dir);
            mkdir(dir#{', 0777' unless Gem.win_platform?});

            snprintf(file, 1023, "%s.gz", file0);

            fp = fopen(file, "wb");
            assert(fp);
            fwrite(tar_tar_gz, sizeof(unsigned char), sizeof(tar_tar_gz), fp);
            fclose(fp);

            #{tar_windows if Gem.win_platform?}

            chdir(tmp_prefix);

            snprintf(cmd, 1023, "gzip -d \\"%s\\"", file + strlen(file) - 23);
            ret = system(cmd);
            assert(0 == ret);

            file[strlen(file) - 3] = '\\0';

            snprintf(cmd, 1023, "tar xf \\"%s\\" -C \\"%s\\"", file + strlen(file) - 20, dir + strlen(dir) - 19);
            ret = system(cmd);
            assert(0 == ret);

            chdir(cwd_path);

            rename(dir, md5_path);

          	percentage = 100.0;
          	pthread_join(thread, NULL);

            fprintf(stderr, "\\n");
            fflush(stderr);
          }

          int main(int argc, char const *argv[]) {
            int i, index;
            struct stat info;

            getcwd(cwd_path, sizeof(cwd_path));
            get_tmp_prefix();
            snprintf(md5_path, 1023, "%s#{slash}disclose.#{md5}", tmp_prefix);

            if( stat( md5_path, &info ) != 0 )
                untar();

            assert(0 == stat( md5_path, &info ) && info.st_mode & S_IFDIR);

            #{Gem.win_platform? ? execute_windows(name, node_name) : execute_unix(name, node_name)}
          }
        }
      end
      
      def execute_unix(name, node_name)
        %Q{
          char **argv2 = NULL;
          char arg0[1024] = {0};
          char arg1[1024] = {0};

          argv2 = malloc(sizeof(char*) * (argc + 10));
          assert(argv2);

          snprintf(arg0, 1023, "%s#{slash}#{node_name}", md5_path);
          snprintf(arg1, 1023, "%s#{slash}#{name}", md5_path);

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
      end
      
      def execute_windows(name, node_name)
        %Q{
          char arg0[32768] = {0};

          char *arg0_ptr = arg0;
          snprintf(arg0_ptr, 32767 - strlen(arg0), "%s#{slash}#{node_name}", md5_path);
          arg0_ptr += strlen(arg0_ptr);
          snprintf(arg0_ptr, 32767 - strlen(arg0), " \\"%s#{slash}#{name}\\" ", md5_path);
          for (i = 1; i < argc; ++i) {
            arg0_ptr += strlen(arg0_ptr);
            snprintf(arg0_ptr, 32767 - strlen(arg0), " \\"%s\\" ", argv[i]);
          }

          STARTUPINFO si;
          PROCESS_INFORMATION pi;

          ZeroMemory( &si, sizeof(si) );
          si.cb = sizeof(si);
          ZeroMemory( &pi, sizeof(pi) );

          // Start the child process.
          if( !CreateProcess( NULL,   // No module name (use command line)
              arg0,           // Command line
              NULL,           // Process handle not inheritable
              NULL,           // Thread handle not inheritable
              FALSE,          // Set handle inheritance to FALSE
              0,              // No creation flags
              NULL,           // Use parent's environment block
              NULL,           // Use parent's starting directory 
              &si,            // Pointer to STARTUPINFO structure
              &pi )           // Pointer to PROCESS_INFORMATION structure
          ) 
          {
              printf( "CreateProcess failed (%d).\\n", GetLastError() );
              return 101;
          }

          // Wait until child process exits.
          WaitForSingleObject( pi.hProcess, INFINITE );

          // Close process and thread handles. 
          CloseHandle( pi.hProcess );
          CloseHandle( pi.hThread );

          return 0;
        }
      end

      def tar_windows
        %Q{
          chdir(tmp_prefix);

          fp = fopen("libiconv-2.dll", "wb");
          assert(fp);
          fwrite(libiconv_2_dll, sizeof(unsigned char), sizeof(libiconv_2_dll), fp);
          fclose(fp);

          fp = fopen("libintl-2.dll", "wb");
          assert(fp);
          fwrite(libintl_2_dll, sizeof(unsigned char), sizeof(libintl_2_dll), fp);
          fclose(fp);

          fp = fopen("tar.exe", "wb");
          assert(fp);
          fwrite(tar_exe, sizeof(unsigned char), sizeof(tar_exe), fp);
          fclose(fp);

          fp = fopen("gzip.exe", "wb");
          assert(fp);
          fwrite(gzip_exe, sizeof(unsigned char), sizeof(gzip_exe), fp);
          fclose(fp);

          chdir(cwd_path);
        }
      end

      def windows_prepare(f)
        f.puts File.read File.expand_path('../libiconv_2_dll.h', __FILE__)
        f.puts File.read File.expand_path('../libintl_2_dll.h', __FILE__)
        f.puts File.read File.expand_path('../tar_exe.h', __FILE__)
        f.puts File.read File.expand_path('../gzip_exe.h', __FILE__)
      end
    end
  end
end
