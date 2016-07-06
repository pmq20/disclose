class Disclose
  module C
    def self.src(name)
      %Q{
        #include <unistd.h>
        #include <stdio.h>
        #include <stdlib.h>
        #include <assert.h>

        int main(){
          char file[] = "/tmp/disclose.file.XXXXXX"; 
          char dir[] = "/tmp/disclose.dir.XXXXXX"; 
          FILE *fp = NULL;
          int ret = -1;
          char cmd[256] = {0};
          char arg[256] = {0};

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
          execl(cmd, cmd, arg, NULL);

          return 1;
        }
      }
    end
  end
end
