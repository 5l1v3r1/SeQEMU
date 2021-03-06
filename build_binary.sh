#!/bin/sh

mkdir build_i386_linux_user
cd build_i386_linux_user

cat <<EOF > test-relro.c
#include <stdio.h>

void hacked(char *s){
	printf("[HACKED] %s\n",s);
}

int main()
{
	void *got;
	unsigned int func;

	puts("This is puts function output");

	got = (void *)0x80497b8;
	func = hacked;

	printf("Write %x in %x!\n",func,got);
	*(unsigned int *)got = func;

	puts("This is second puts function output");

	return 0;
}

EOF

gcc -o test-relro -m32 -fno-PIE -z execstack -fno-stack-protector -fno-PIE -Wl,-z,norelro test-relro.c

cat <<EOF > test-uaf.c
#include <stdio.h>
#include <stdlib.h>

int main()
{
	char *ptr = (char *)malloc(sizeof(char) * 20);

	fgets(ptr,20,stdin);

	free(ptr);

	fgets(ptr,20,stdin);

	puts("End of Use After Free");

	return 0;
}

EOF

gcc -o test-uaf -m32 -fno-PIE -z execstack -fno-stack-protector -fno-PIE -Wl,-z,norelro test-uaf.c

cat <<EOF > test-nx.c
#include <stdio.h>
char shellcode[] = "\x68\x2f\x73\x68\x00\x68\x2f\x62\x69\x6e\x89\xe3\x31\xd2\x52\x53\x89\xe1\xb8\x0b\x00\x00\x00\xcd\x80";

int main()
{
    printf("Now, let's start shellcode!\n");
    (*(void (*)())shellcode)();
}

EOF

gcc -o test-nx -m32 -fno-PIE -z execstack -fno-stack-protector -fno-PIE -Wl,-z,norelro test-nx.c

cat <<EOF > test-normal.c
#include <stdio.h>

int main(void){
	char buf[100] = {0};

	fgets(buf,sizeof(buf),stdin);
	printf("%s",buf);
	memset(buf,0x0,sizeof(buf));

	fgets(buf,sizeof(buf),stdin);
	printf("%s",buf);
	memset(buf,0x0,sizeof(buf));

	fgets(buf,sizeof(buf),stdin);
	printf("%s",buf);
	memset(buf,0x0,sizeof(buf));

	return 0;
}

EOF

gcc -o test-normal -m32 test-normal.c

cat <<EOF > test-all.c
#include <stdio.h>
#include <string.h>
#include <malloc.h>
int main(void){
	int i;
	for(i = 0; i < 100; i++){
		printf("[%d] Hello world!\n",i);
	}
	printf("Exited!\n");

	char *buf = (char *)malloc(sizeof(char) * 10);
	gets(buf);
	memcpy(buf,buf,10);
	free(buf);

	return 0;
}

EOF

gcc -o test-all -m32 test-all.c


cat <<EOF > test-dangerous.c
#include <stdio.h>

int main(void){
	char buf[100];

	gets(buf);

	printf(buf);

	return 0;
}

EOF

gcc -o test-dangerous-disable-sec -m32 -fno-PIE -z execstack -fno-stack-protector -fno-PIE -Wl,-z,norelro test-dangerous.c
gcc -o test-dangerous-no-execstack -m32 -fno-PIE -fno-stack-protector -Wl,-z,norelro test-dangerous.c
gcc -o test-dangerous-stack-protector -m32 -fno-PIE -z execstack -fstack-protector -Wl,-z,norelro test-dangerous.c
gcc -o test-dangerous-relro-lazy -m32 -fno-PIE -z execstack -fno-stack-protector -Wl,-z,relro,-z,lazy test-dangerous.c
gcc -o test-dangerous-relro-now -m32 -fno-PIE -z execstack -fno-stack-protector -Wl,-z,relro,-z,now test-dangerous.c
gcc -o test-dangerous-pie -m32 -fPIE -pie -z execstack -fno-stack-protector -Wl,-z,norelro test-dangerous.c

cat <<EOF > test-format.c
#include <stdio.h>

char format1[] = "%x %n %x";
char format2[] = "%d %3\$n %x";

int main(void){
	puts(format1);
	printf(format1,1,2,3);
	printf("\n\n");

	puts(format2);
	printf(format2,1,2,3);
	printf("\n");

	return 0;
}
EOF

gcc -o test-format -m32 test-format.c

cat <<EOF > test-buffer.c
#include <stdio.h>

void func(void){
	char buf[10];

	printf("Input message : ");
	fgets(buf,30,stdin);

	printf("message : ");
	puts(buf);
}

int main(void){
	func();

	printf("OK! Control Flow is protected!\n");

	return 0;
}

EOF

gcc -o test-buffer -m32 test-buffer.c -fno-stack-protector

cat <<EOF > test-df.c
#include <stdio.h>
#include <malloc.h>

int main(void){
	char *ptr;

	ptr = (char *)malloc(sizeof(char) * 20);
	printf("Pointer = %p\n",ptr);
	printf("Input message : ");
	fgets(ptr,20,stdin);
	printf("%s\nLet's Double free!\n",ptr);

	free(ptr);
	free(ptr);

	printf("Double Free is End!\n");

	return 0;
}

EOF

gcc -o test-df -m32 test-df.c


cat <<EOF > test-pie.c
#include <stdio.h>

int main(void){
	printf("main = %p\n",main);
	return 0;
}

EOF

gcc -o test-pie -m32 -fPIE -pie test-pie.c


cat <<EOF > test-open.c
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

int main(void){
	printf("Now open \"flag.txt\"\n");
	unsigned int fd = open("flag.txt",O_RDONLY);
	printf("fd = %u\n",fd);

	return 0;
}

EOF

gcc -o test-open -m32 -fPIE -pie test-open.c

echo "FLAG{THIS_IS_A_FLAG}" > flag.txt
mv flag.txt i386-linux-user/
