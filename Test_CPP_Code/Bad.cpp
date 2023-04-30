/*
This programme demonstrates incorrect CPP Syntax and typing for the Type Checker. 
This code should not pass the Typer checker and should produce an error.
Author: Deja Scott
Course: CSCE 531 J50
Professor: Dr Marco Valtorta
*/

#include <iostream>

int main(int argc, char* argv[]) {
    int n = 26;

    while n--;

    if (n < 20) {
        std::cout << true << std::endl;
    } else {
        std::cout << false << std::endl;
    }

    return 0;
}