function main()
{
	variable queue:string MyQueue
	echo \${MyQueue.Used} should be 0: ${MyQueue.Used}
	MyQueue:Queue[Fifteen]
	echo \${MyQueue.Used} should be 1: ${MyQueue.Used}
	MyQueue:Queue[Twenty Five]
	echo \${MyQueue.Used} should be 2: ${MyQueue.Used}
	echo \${MyQueue.Peek} should be 15: ${MyQueue.Peek}
	MyQueue:Dequeue
	echo \${MyQueue.Used} should be 1: ${MyQueue.Used}
	/* Only 25 is now in the queue */
	echo \${MyQueue.Peek} should be 25: ${MyQueue.Peek}
	MyQueue:Dequeue
	echo \${MyQueue.Used} should be 0: ${MyQueue.Used}
	echo \${MyQueue.Peek} should be null: ${MyQueue.Peek}
}

