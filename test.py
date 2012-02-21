import unittest2
import threading, socket
from logging import info as INFO, error as ERROR, debug as DEBUG


from wsgiref.simple_server import make_server
import hate

        





class Test(unittest2.TestCase):
    def testCase(self):
        cases = [
            1,
            1.0,
            "foo",
            u"bar",
            [],
            ['a',1,[2]],
            None,
            True,
            False,
            {'a':1}
        ]
        for c in cases:
            self.assertEqual(c, hate.parse(hate.dump(c)))


class NodeTest(unittest2.TestCase):
    def testCase(self):
        cases = [
            hate.node('doc',attributes=dict(aa=1,b="toot")),
            hate.form("http://example.org",values=['a','b']),
            hate.link("http://toot.org")
        ]
        for c in cases:
            self.assertEqual(c, hate.parse(hate.dump(c)))



class ServerTest(unittest2.TestCase):
    def setUp(self):
        self.endpoint=hate.Server(self.mapper())
        self.endpoint.start()

    def tearDown(self):
        self.endpoint.stop()

class GetTest(ServerTest):
    def setUp(self):
        self.value = 0
        ServerTest.setUp(self)

    def mapper(self):
        m = hate.Mapper()
        @m.default()
        class Testr(hate.r):
            def get(self_):
                return self.value
        return m

    def testCase(self):
        result = hate.get(self.endpoint.url)
        self.assertEqual(result, self.value)

class LinkTest(ServerTest):
    def setUp(self):
        self.value = 0
        ServerTest.setUp(self)

    def mapper(self):
        m = hate.Mapper()
        @m.add()
        class Testr(hate.r):
            def __init__(self, value):
                self.value = int(value)
            def get(self):
                return self.value
        @m.default()
        class Rootr(hate.r):
            def get(self_):
                return hate.link(Testr(self.value))
        return m

    def testCase(self):
        result = hate.get(self.endpoint.url)
        result = result()
        self.assertEqual(result, self.value)


class MethodTest(ServerTest):
    def setUp(self):
        ServerTest.setUp(self)

    def mapper(self):
        m = hate.Mapper()
        @m.default()
        class Testr(hate.r):
            def __init__(self, value=0):
                self.value = int(value)
            def inc(self, n):
                raise hate.Redirect(Testr(self.value+n))
        return m

    def testCase(self):
        result = hate.get(self.endpoint.url)
        self.assertEqual(result.value, 0)
        print result
        result = result.inc(n=5)
        self.assertEqual(result.value, 5)
if __name__ == '__main__':
    unittest2.main()
