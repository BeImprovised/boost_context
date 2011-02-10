
//          Copyright Oliver Kowalke 2009.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

#include <sstream>
#include <stdexcept>
#include <string>

#include <boost/assert.hpp>
#include <boost/test/unit_test.hpp>
#include <boost/utility.hpp>

#include <boost/context/all.hpp>

int value1 = 0;
std::string value2;

void fn1( void *) {}

void fn2( void * vp)
{ value1 = * ( ( int *) vp); }

void fn3( void * vp)
{
    try
    { throw std::runtime_error("abc"); }
    catch ( std::runtime_error const& e)
    { value2 = e.what(); }
}

void test_case_1()
{
    boost::protected_stack stack1( 65536);
    BOOST_CHECK( stack1);
    boost::protected_stack stack2;
    BOOST_CHECK( ! stack2);
}

void test_case_2()
{
    boost::protected_stack stack( 65536);
    BOOST_CHECK_EQUAL( 65536, stack.size() );
    BOOST_CHECK( stack.address() );
}

void test_case_3()
{
    boost::protected_stack stack1( 65536);
    boost::protected_stack stack2;
    BOOST_CHECK( stack1);
    BOOST_CHECK( ! stack2);
    stack2 = boost::move( stack1);
    BOOST_CHECK( ! stack1);
    BOOST_CHECK( stack2);
}

void test_case_4()
{
    boost::protected_stack stack1( 65536);
    boost::protected_stack stack2;
    BOOST_CHECK( stack1);
    BOOST_CHECK( ! stack2);
    stack2.swap( stack1);
    BOOST_CHECK( ! stack1);
    BOOST_CHECK( stack2);
}

boost::unit_test::test_suite * init_unit_test_suite( int, char* [])
{
    boost::unit_test::test_suite * test =
        BOOST_TEST_SUITE("Boost.Context: protected_stack test suite");

    test->add( BOOST_TEST_CASE( & test_case_1) );
    test->add( BOOST_TEST_CASE( & test_case_2) );
    test->add( BOOST_TEST_CASE( & test_case_3) );
    test->add( BOOST_TEST_CASE( & test_case_4) );

    return test;
}
