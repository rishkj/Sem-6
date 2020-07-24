#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include"intal.h"

//My helper funtions
static int char_to_digit(char dig)
{
    return dig - '0';
}

static char digit_to_char(int dig)
{
    return dig + '0';
}


static char* get_diff(const char* intal1, const char* intal2)
{
    int carry = 0;

    int len1 = strlen(intal1);
    int len2 = strlen(intal2);

    int size_of_diff = len1+1;
    char *diff = (char *)malloc(sizeof(char)*size_of_diff);

    diff[len1] = '\0';

    len1--;
    len2--;
    while(len2>=0)
    {
        int flag = 0;
        int dig1 = char_to_digit(intal1[len1]);
        if(dig1 == 0 && carry != 0)
        {
            dig1 = 9;
            carry = 1;
            flag = 1;
        }
        else
        {
            dig1 = dig1-carry;
        }

        int dig2 = char_to_digit(intal2[len2]);

        if(dig1 < dig2)
        {
            dig1 = dig1+10;
            carry = 1;
        }
        else
        {
            if(flag == 0)
            {
                carry = 0;
            }
        }

        diff[len1] = digit_to_char(dig1-dig2);

        len1--;
        len2--;
    }
    
    while(len1>=0)
    {
        int flag = 0;
        int dig1 = char_to_digit(intal1[len1]);
        if(dig1 == 0 && carry != 0)
        {
            dig1 = 9;
            carry = 1;
            flag = 1;
        }
        else
        {
            dig1 = dig1-carry;
        }

        diff[len1] = digit_to_char(dig1);
        len1--;
        
        if(flag == 0)
        {
            carry = 0;
        }
    }

    len1 = 0;
    while(diff[len1] == '0')
    {
        if(len1 == size_of_diff-2)
        {
            break;
        }
        len1++;
    }
    char *final_diff = (char *)malloc(sizeof(char)*size_of_diff-len1);
    strcpy(final_diff,diff+len1);
    free(diff);

    return final_diff;
}


static void merge_sort(char **arr, int l, int mid, int r)
{
    char *arr1[r-l+1];
    int index = 0;

    int i=l;
    int j=mid+1;

    while(i<=mid && j<=r)
    {
        if(intal_compare(arr[i],arr[j])>=0)
        {
            arr1[index] = arr[j];
            j++;
        }
        else
        {
            arr1[index] = arr[i];
            i++;
        }
        index++;
    }

    while(i<=mid)
    {
        arr1[index] = arr[i];
        i++;
        index++;
    }
    while(j<=r)
    {
        arr1[index] = arr[j];
        j++;
        index++;
    }

    for(int i=0;i<index;i++)
    {
        arr[l+i] = arr1[i];
    }
}

static void merge(char **arr,int l, int r)
{
    if(l<r)
    {
        int mid = (l+r)/2;

        merge(arr,l,mid);
        merge(arr,mid+1,r);
        merge_sort(arr,l,mid,r);
    }
}


static char *get_gcd(char *intal1,char *intal2)
{
    char *gcd_res = intal1;
    while(intal_compare(intal2,"0") != 0)
    {
        gcd_res = intal_mod(intal1,intal2);
        free(intal1);
        intal1 = intal2;
        intal2 = gcd_res;
    }
    free(gcd_res);

    return intal1;
}
//Helper functions over


char* intal_add(const char* intal1,const char* intal2)
{
    int len1 = strlen(intal1);
    int len2 = strlen(intal2);
    int size_of_sum = 0;
    if(len1 >= len2)
    {
        size_of_sum = len1+1;
    }
    else if(len1<len2)
    {
        size_of_sum = len2+1;
    }

    char *sum = (char *)malloc(sizeof(char)*(size_of_sum+1));
    sum[size_of_sum] = '\0';

    int i = size_of_sum - 1;
    len1--;
    len2--;

    int sum_of_digit = 0;
    int carry = 0;
    while(len1 >= 0 && len2 >= 0)
    {
        sum_of_digit = char_to_digit(intal1[len1]) + char_to_digit(intal2[len2]) + carry;
        if(sum_of_digit > 9)
        {
            carry = 1;
            sum_of_digit -= 10;
        }
        else
        {
            carry = 0;
        }

        sum[i] = digit_to_char(sum_of_digit);
        i--;

        len1--;
        len2--;
    }

    if(len1 >= 0 || len2 >= 0)
    {
        if(len1 >= 0)
        {
            while(len1 >= 0)
            {
                sum_of_digit = carry + char_to_digit(intal1[len1]);
                if(sum_of_digit > 9)
                {
                    carry = 1;
                    sum_of_digit -= 10;
                }
                else
                {
                    carry = 0;
                }
                
                sum[i] = digit_to_char(sum_of_digit);
                len1--;
                i--;
            }
        }
        else
        {
            while(len2 >= 0)
            {
                sum_of_digit = carry + char_to_digit(intal2[len2]);
                if(sum_of_digit > 9)
                {
                    carry = 1;
                    sum_of_digit -= 10;
                }
                else
                {
                    carry = 0;
                }
                
                sum[i] = digit_to_char(sum_of_digit);
                len2--;
                i--;
            }
        } 
    }

    if(carry > 0)
    {
        sum[i] = digit_to_char(carry);
        i--;
    }

    char *final_sum = malloc(sizeof(char)*1001);
    strcpy(final_sum,sum+i+1);
    free(sum);

    return final_sum;
}


int intal_compare(const char* intal1, const char* intal2)
{
    int len1 = strlen(intal1);
    int len2 = strlen(intal2);

    if(len1>len2)
    {
        return 1;
    }
    else if(len1<len2)
    {
        return -1;
    }

    for(int i=0;i<len1;i++)
    {
         if(intal1[i] != intal2[i])
         {
             if(intal1[i] < intal2[i])
             {
                 return -1;
             }
             else
             {
                 return 1;
             }
         }
    }

    return 0;
}

char* intal_diff(const char* intal1, const char* intal2)
{
    char *diff;
    
    int res = intal_compare(intal1,intal2);
    if(res == 0)
    {
        char *diff = (char*)malloc(sizeof(char)*2);
        strcpy(diff,"0");
        return diff;
    }
    else if(res == 1)
    {
        diff = get_diff(intal1,intal2);
    }
    else
    {
        diff = get_diff(intal2,intal1);
    }

    return diff;
}


char* intal_multiply(const char* intal1, const char* intal2)
{
    if(intal_compare(intal1,"0") == 0 || intal_compare(intal2,"0") == 0)
    {
        char *res = (char *)malloc(sizeof(char)*2);
        strcpy(res,"0");
        return res;
    }
    
    int len1 = strlen(intal1);
    int len2 = strlen(intal2);

    int size_of_prod = len1+len2+2;
    char *prod = (char*)malloc(sizeof(char)*size_of_prod);

    int *prodint = (int *)calloc(size_of_prod,sizeof(int));

    int carry;
    int mult;
    int dig1,dig2;
    int last_index = size_of_prod-2;
    int index;

    for(int i=len1-1;i>=0;i--)
    {
        dig1 = char_to_digit(intal1[i]);
        carry = 0;
        index = last_index;
        for(int j = len2-1;j>=0;j--)
        {
            dig2 = char_to_digit(intal2[j]);
            mult = dig1*dig2 + carry;

            carry = mult/10;
            mult = mult%10;

            prodint[index] += mult;
            index--;
        }
        if(carry > 0)
        {
            prodint[index] += carry;
        }
        else
        {
            index++;
        }
        
        last_index--;
    }
    
    int i=0;
    carry = 0;

    for(int j=size_of_prod-2;j>=index;j--)
    {
        prodint[j] += carry;
        carry = prodint[j]/10;
        prodint[j] %= 10;
    }
    if(carry>0)
    {
        prodint[--index] = carry;
    }
    
    while(index<size_of_prod-1)
    {
        prod[i] = digit_to_char(prodint[index]);
        index++;
        i++;
    }
    free(prodint);
    prod[i] = '\0';
    return prod;
}


char* intal_mod(const char* intal1, const char* intal2)
{
    int len1 = strlen(intal1);
    int len2 = strlen(intal2);

    char *diff = (char *)malloc(sizeof(char)*1001);
    strcpy(diff,intal1);

    char *temp_intal2 = (char *)malloc(sizeof(char)*1001);
    strcpy(temp_intal2,intal2);

    int len_temp = len2;
    while(len1 - len_temp > 1)
    {
        temp_intal2[len_temp] = '0';
        len_temp++;
    }
    temp_intal2[len_temp] = '\0';

    while(intal_compare(diff,intal2) >= 0)
    {
        while(intal_compare(diff,temp_intal2) >= 0)
        {
            char *temp_diff = intal_diff(diff,temp_intal2);
            free(diff);
            diff = temp_diff;
        }

        len_temp--;
        temp_intal2[len_temp] = '\0';
    }

    free(temp_intal2);

    return diff;
}


char* intal_pow(const char* intal1, unsigned int n)
{
    char *res;
    if(n == 0)
    {
        res = (char *)malloc(sizeof(char)*2);
        strcpy(res,"1");
        return res;
    }

    if(strcmp(intal1,"0") == 0)
    {
        res = (char *)malloc(sizeof(char)*2);
        strcpy(res,"0");
        return res;
    }
    char *temp;
    res = (char *)malloc(sizeof(char)*2);
    strcpy(res,"1");

    char *intal_temp = (char *)malloc(sizeof(char)*1001);
    strcpy(intal_temp,intal1);

    while(n>0)
    {
        if(n%2 == 1)
        {
            temp = intal_multiply(res,intal_temp);
            free(res);
            res = temp;
        }

        n = n/2;
        char *temp1 = intal_multiply(intal_temp,intal_temp);
        free(intal_temp);
        intal_temp = temp1;        
    }
    free(intal_temp);
    return res;
}


char* intal_gcd(const char* intal1, const char* intal2)
{
    int res = intal_compare(intal1,intal2);

    char *intal_first = (char *)malloc(sizeof(char)*1001);
    strcpy(intal_first,intal1);

    char *intal_second = (char *)malloc(sizeof(char)*1001);
    strcpy(intal_second,intal2);

    char *gcd_res;

    if(res == 0)
    {
        free(intal_first);
        return intal_second;
    }
    else if(res == 1)
    {
        gcd_res = get_gcd(intal_first,intal_second);
    }
    else
    {
        gcd_res = get_gcd(intal_second,intal_first);
    }

    return gcd_res;
}


char* intal_fibonacci(unsigned int n)
{
    char *first = (char *)malloc(sizeof(char)*1001);
    strcpy(first,"0");
    if(n == 0)
    {
        return first;
    }

    char *second = (char *)malloc(sizeof(char)*1001);
    strcpy(second,"1");
    if(n == 1)
    {
        free(first);
        return second;
    }

    char *res;
    for(int i=2;i<=n;i++)
    {
        res = intal_add(first,second);
        free(first);
        first = second;
        second = res;
    }
    free(first);
    
    return res;
}


char* intal_factorial(unsigned int n)
{
    char *fact_res = (char *)malloc(sizeof(char)*2);
    strcpy(fact_res,"1");

    if(n == 0)
    {
        return fact_res;
    }
    
    char *get_next_multiplier_temp;
    char *get_next_multiplier = (char *)malloc(sizeof(char)*2);
    strcpy(get_next_multiplier,"1");

    
    char *final_fact_res = fact_res;

    for(int i=2;i<=n;i++)
    {
        get_next_multiplier_temp = intal_add(get_next_multiplier,"1");
        free(get_next_multiplier);
        get_next_multiplier = get_next_multiplier_temp;
        
        final_fact_res = intal_multiply(get_next_multiplier,fact_res);

        free(fact_res);
        fact_res = final_fact_res;
    }

    free(get_next_multiplier);
    return final_fact_res;
}


char* intal_bincoeff(unsigned int n, unsigned int k)
{   
    if(n == 1)
    {
        char *res = (char *)malloc(sizeof(char)*1001);
        strcpy(res,"1");
        return res;
    }
    
    if(n-k < k)
    {
        k = n-k;
    }
    char *intals[k+1];

    intals[0] = (char *)malloc(sizeof(char)*1001);
    strcpy(intals[0],"1");

    intals[1] = (char *)malloc(sizeof(char)*1001);
    strcpy(intals[1],"1");

    char *temp_intal;
    char *temp_intal_next;

    for(int i=2;i<=n;i++)
    {
        for(int j=1;j<=k && j<=i;j++)
        {
            if(j == i)
            {
                intals[j] = (char *)malloc(sizeof(char)*1001);
                strcpy(intals[j],"1");

                free(intals[j-1]);
                intals[j-1] = temp_intal;
                
                break;
            }
            temp_intal_next = intal_add(intals[j],intals[j-1]);
            if(j != 1)
            {
                free(intals[j-1]);
                intals[j-1] = temp_intal;
            }
            temp_intal = temp_intal_next;
        }
        if(k<i)
        {
            free(intals[k]);
            intals[k] = temp_intal;
        }
    }

    for(int i=0;i<k;i++)
    {
        free(intals[i]);
    }
    return intals[k];
}


int intal_max(char **arr, int n)
{
    int req_index = 0;
    for(int i=1;i<n;i++)
    {
        if(intal_compare(arr[i],arr[req_index]) == 1)
        {
            req_index = i;
        }
    }

    return req_index;
}


int intal_min(char **arr, int n)
{
    int req_index = 0;
    for(int i=1;i<n;i++)
    {
        if(intal_compare(arr[i],arr[req_index]) == -1)
        {
            req_index = i;
        }
    }

    return req_index;
}


int intal_search(char **arr, int n, const char* key)
{
    for(int i=0;i<n;i++)
    {
        if(intal_compare(arr[i],key) == 0)
        {
            return i;
        }
    }
    return -1;
}


int intal_binsearch(char **arr, int n, const char* key)
{
    int l = 0;
    int r=n-1;
    int mid;
    int index = -1;

    while(l<=r)
    {
        mid = (l+r)/2;
        int res = intal_compare(arr[mid],key);
        if(res == 0)
        {
            index = mid;
            r = mid-1;
        }
        else if(res == 1)
        {
            r = mid-1;
        }
        else
        {
            l=mid+1;
        }      
    }
    return index;
}


void intal_sort(char **arr, int n)
{
    if(n == 1)
    {
        return;
    }

    int l = 0;
    int r=n-1;
    merge(arr,l,r);
}


char* coin_row_problem(char **arr, int n)
{
    if(n == 1)
    {
        char *res = (char *)malloc(sizeof(char)*1001);
        strcpy(res,arr[0]);
        return res;
    }
    
    char *odd_index = (char *)malloc(sizeof(char)*1001);
    strcpy(odd_index,"0");

    char *even_index = (char *)malloc(sizeof(char)*1001);
    strcpy(even_index,arr[0]);

    char *final_res;
    char *res;

    for(int i=1;i<n;i++)
    {
        if(i%2 == 0)
        {
            res = intal_add(even_index,arr[i]);
            if(intal_compare(res,odd_index) >= 0)
            {
                free(even_index);
                even_index = res;
                final_res = res;
            }
            else
            {
                strcpy(even_index,odd_index);
                free(res);
                final_res = odd_index;
            } 
        }
        else
        {
            res = intal_add(odd_index,arr[i]);
            if(intal_compare(res,even_index) >= 0)
            {
                free(odd_index);
                odd_index = res;
                final_res = res;
            }
            else
            {
                strcpy(odd_index,even_index);
                free(res);
                final_res = even_index;
            } 
        }
    }

    if(final_res == odd_index)
    {
        free(even_index);
    }
    else
    {
        free(odd_index);
    }
    
    return final_res;
}