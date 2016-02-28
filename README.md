# Dockers-benchmarks

As part of our class project, we have worked on benchmarking different Docker storage backends on some criteria.
One of the essential and integral part of the Docker model is the optimum use of images and containers based on those images.
To implement containers based on the images, Docker relies on different file systems features in the kernel. 
The primary reason of using filesystems in the Docker is abstraction of storage backend.
A storage backend enables us to use a set of layers that are addressed by a unique name. 
These layers form a different filesystem which can be mounted on backend as per requirement.
Solution:-
We  automated the process through shell scripting and the environment was setup on Amazon EC2 and docker was running on it. We intergrated
the result with google chart API for visualization.
Various I/O benchmarking tools are available like FIO, IOZONE, bonnie++, FileBench etc.
While comparing all the backends against each other we found that FIO has a strong advantage over others.
FIO is used for both benchmarking and hardware/stress level verification.
It has support for different type of IO engines (like sync, mmap, libaio, etc).
It works on both blocks and file level.
FIO is widely supported on Linux, FreeBSD, NetBSD, OS X, OpenSolaris, AIX, HP-UX, and Windows. 
The FIO benchmarking can prove a good benchmarking tool for choosing the most efficient file system between vfs, devicemapper, and aufs.

Conclusion:-
•	AUFS introduces write latency.
•	Device mapper is useful for small applications and nimble developers. It is not useful for I/O and heavy workloads because of loopback mounted thinp volumes.
•	AUFS, Devicemapper , btrfs do not use page cache sharing whereas Overlayfs uses page cache sharing and is fast.
•	Vfs does not use copy-on-write and so might degrade performance.
•	Overlayfs and AUFS are not in the upstream kernel.
