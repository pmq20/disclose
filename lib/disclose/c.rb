class Disclose
  module C
    def self.src(name)
      %Q{
        #include <unistd.h>
        #include <stdio.h>
        #include <stdlib.h>
        #include <assert.h>

        int main(int argc, char const *argv[]) {
          char file[] = "/tmp/disclose.file.XXXXXX";
          char dir[] = "/tmp/disclose.dir.XXXXXX";
          FILE *fp = NULL;
          int ret = -1;
          char cmd[256] = {0};
          char arg[256] = {0};
          char **argv2 = NULL;
          int i, index;

          mktemp(file);
          mkdtemp(dir);

          fp = fopen(file, "wb");
          assert(fp);

          fwrite(tar_tar, sizeof(unsigned char), sizeof(tar_tar), fp);
          fclose(fp);

          snprintf(cmd, 255, "tar xf %s -C %s", file, dir);
          ret = system(cmd);
          assert(0 == ret);

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
  end
end
