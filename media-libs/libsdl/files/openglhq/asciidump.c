#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int main(int argc, char *argv[])
{
	FILE *dat, *hdr;
	char buffer[256], *name;
	int i;

	if (argc != 3) {
		fprintf(stderr,"wrong number of arguments\n");
		exit(1);
	}

	dat = fopen(argv[1],"rb");
	hdr = fopen(argv[2],"w");
	if (dat == NULL || hdr == NULL) {
		perror("file open");
		exit(2);
	}

#if defined (_MSC_VER)
	name = strrchr(argv[1],'\\');
#else
	name = strrchr(argv[1],'/');
#endif
	if (name == NULL) name=argv[1];
	else name++;
	name = strdup(name);

	for (i = 0; name[i]; i++)
		if (!((name[i]>='a' && name[i]<='z') || (name[i]>='A' && name[i]<='Z') || (name[i]>='0' && name[i]<='9')))
			name[i] = '_';

	fprintf(hdr,"#define %s \\\n", name);
	while (!feof(dat) && fgets(buffer,256,dat)) {
		buffer[strlen(buffer)-1] = 0;

		name = buffer;
		while (*name == ' ' || *name == '\t') name++;
		if (*name == 0 || *name == '#') continue;
		
		fprintf(hdr,"\"%s\\n\" \\\n",name);
	}
	fprintf(hdr,"\n");
	fclose(hdr);
	fclose(dat);

	return 0;
}
