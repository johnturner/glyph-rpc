import hate

def client(endpoint):
    broker = hate.get(endpoint)
    # broker is a page, with a single element, 'queue' which is a form
    queue = broker.queue(name='help')
    # submitting this form takes us to the page for the queue
    print queue.push
    queue.push('help')
    # queue has two forms, 'push', 'pop'
    print queue.pop()


def server():
    import collections

    queues = {}

    m = hate.map()

    # these are created on each request
    @m.default()
    class Broker(hate.r):
        def queue(self, name):
            raise hate.Redirect(Queue(name))

    # the url parameters are used to construct them
    @m.add()
    class Queue(hate.r):
        def __init__(self, name):
            self.name = name
        def push(self, msg):
            if self.name not in queues:
                queues[self.name]=collections.deque()
            queues[self.name].appendleft(msg)

        def pop(self):
            if self.name in queues:
                return queues[self.name].popleft()

    s = hate.Server(m)
    s.start()
    print s.url
    try:
        while s.is_alive():
            s.join(2)
    finally:
        s.stop()

if __name__ == '__main__':
    import sys
    if len(sys.argv) > 1:
        client(sys.argv[1])
    else:
        server()

