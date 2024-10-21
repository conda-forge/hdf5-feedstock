
#include <iostream>
#include <H5Cpp.h>

int main()
{
    H5::Exception::dontPrint();
    
    H5::H5File *keaImgH5File = new H5::H5File("/tmp/test.hd5", H5F_ACC_TRUNC, H5::FileCreatPropList::DEFAULT);
    keaImgH5File->createGroup("/HEADER");
    
    H5::DataSet ds;
    try
    {
        // should fail
        ds = keaImgH5File->openDataSet("/HEADER/NUMBANDS");
        std::cout << "Was able to open dataset\n";
    }
    catch (const H5::Exception &e)
    {
        std::cout << "Failed to open dataset (expected)\n";
    }
    
    return 0;
}



