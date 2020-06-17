#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>

class Policytype {
    public: 
        virtual void replacepage(long pagenum) = 0;
        virtual int findpage(long pagenum) = 0;
        virtual void init(long pagecount) = 0;
        virtual void print() = 0;
        virtual long getFaults() = 0;
        virtual const char* getName() = 0;
};

class Clockpolicy : public Policytype {
    private:
        long * pagetable;
        char * used;
        long pagecount;
        long nextpage;
        long pagefaults;

    public:
        void replacepage(long pagenum){
            while(used[nextpage]){
                used[nextpage] = 0;
                nextpage++;
                nextpage %= pagecount;
            }
            used[nextpage] = 1;
            pagetable[nextpage] = pagenum;
            pagefaults++;
            nextpage++;
            nextpage %= pagecount;
        }

        int findpage(long pagenum){
            for(int i = 0; i < pagecount; i++){
                if(pagetable[i] == pagenum){
                    used[i] = 1;
                    return 1;
                }
            }
            return 0;
        }

        void init(long pagect){
            nextpage = 0;
            pagefaults = 0;
            pagetable = (long *)malloc(pagect * sizeof(long));
            used = (char *)calloc(pagect, sizeof(char));
            pagecount = pagect;
            for (int i = 0; i < pagecount; i++){
                pagetable[i] = -1;
            }
            
        }
        void print(){
            printf("Clock Policy:\n");
            printf("\tPages: %ld\n", pagecount);
        }

        long getFaults(){
            return pagefaults;
        }

        const char* getName(){
            return "Clock";
        }
};


class FIFOpolicy : public Policytype {
    private:
        long * pagetable;
        long pagecount;
        long nextpage;
        long pagefaults;
    public: 
        void init(long pagect){
            pagefaults = 0;
            nextpage = 0;
            pagetable = (long *)malloc(pagect * sizeof(long));
            pagecount = pagect;
            for (int i = 0; i < pagecount; i++){
                pagetable[i] = -1;
            }
            
        }

        int findpage(long pagenum){
            for(int i = 0; i < pagecount; i++){
                if(pagetable[i] == pagenum){
                    return 1;
                }
            }
            return 0;
        }

        void replacepage(long pagenum){
            pagetable[nextpage] = pagenum;
            nextpage++;
            nextpage %= pagecount;
            pagefaults++;
        }

        void print(){
            printf("FIFO Policy:\n");
            printf("\tPages: %ld\n", pagecount);
        }

        long getFaults(){
            return pagefaults;
        }

        const char* getName(){
            return "FIFO";
        }
};
