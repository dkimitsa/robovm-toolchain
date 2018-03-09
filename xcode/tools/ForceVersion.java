import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.BufferUnderflowException;
import java.nio.ByteOrder;
import java.nio.file.DirectoryStream;
import java.nio.file.Files;
import java.nio.file.Path;

public class ForceVersion {

    public static class FileByteReader {
        private ByteOrder byteOrder = ByteOrder.BIG_ENDIAN;
        private final RandomAccessFile file;
        private long position;
        private long limit;
        private long fileStartOffset;


        FileByteReader(RandomAccessFile file) {
            this.file = file;
            try {
                this.limit = file.length();
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        }

        FileByteReader(RandomAccessFile file, ByteOrder byteOrder, long limit, long fileStartOffset) {
            this.file = file;
            this.byteOrder = byteOrder;
            this.limit = limit;
            this.fileStartOffset = fileStartOffset;
        }

        public void close() throws IOException {
            file.close();
        }

        public FileByteReader slice() {
            return new FileByteReader(file, byteOrder, limit - position, fileStartOffset + position);
        }


        public int readInt32() {
            if (position + 4 > limit)
                throw new BufferUnderflowException();

            try {
                synchronized (file) {
                    file.seek(fileStartOffset + position);
                    position += 4;

                    // only buffered read
                    int i = file.readInt();
                    return byteOrder == ByteOrder.BIG_ENDIAN ? i : Integer.reverseBytes(i);
                }
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        }

        public void writeInt32(int v) {
            if (position + 4 > limit)
                throw new BufferUnderflowException();

            try {
                synchronized (file) {
                    file.seek(fileStartOffset + position);
                    position += 4;

                    // only buffered read
                    file.writeInt(byteOrder == ByteOrder.BIG_ENDIAN ? v : Integer.reverseBytes(v));
                }
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        }

        public void setOrder(ByteOrder order) {
            this.byteOrder = order;
        }


        public void setPosition(long offset) {
            if (position < 0 || position > limit)
                throw new IllegalArgumentException();
            this.position = offset;
        }


        public long position() {
            return position;
        }


        public void setLimit(long size) {
            if (size < 0 || size > limit)
                throw new IllegalArgumentException();
            limit = size;
        }
    }

    static class MachOException extends RuntimeException {
        MachOException(String message) {
            super(message);
        }

        MachOException(String message, Throwable cause) {
            super(message, cause);
        }
    }

    /**
     * Very simple mach-o loader
     */
    public static class SimpleMachOLoader implements AutoCloseable {
        static final int LC_ID_DYLIB = 0xd; /* dynamically linked shared lib ident */

        private static final int FAT_MAGIC = 0xcafebabe;
        private static final int FAT_CIGAM = 0xbebafeca;

        private static final int MH_MAGIC = 0xfeedface;
        private static final int MH_CIGAM = 0xcefaedfe; // NXSwapInt(MH_MAGIC)
        private static final int MH_MAGIC_64 = 0xfeedfacf; // the 64-bit mach magic number
        private static final int MH_CIGAM_64 = 0xcffaedfe; // NXSwapInt(MH_MAGIC_64)

        FileByteReader rootReader;

        SimpleMachOLoader(File executable, boolean modify) throws ForceVersion.MachOException {
            try {
                RandomAccessFile executableFile = new RandomAccessFile(executable, modify ? "rw" : "r");
                rootReader = new FileByteReader(executableFile);

                rootReader.setOrder(ByteOrder.BIG_ENDIAN);
            } catch (IOException e) {
                throw new ForceVersion.MachOException("Failed to open mach-o file", e);
            }
        }

        void fixVersions(int currentV, int compatV) {

            try {
                // read architectures
                int magic = rootReader.readInt32();
                if (magic == FAT_CIGAM || magic == FAT_MAGIC) {
                    // get another reader, as fat header always big endian
                    FileByteReader fatReader = rootReader.slice();
                    fatReader.setOrder(magic == FAT_MAGIC ? ByteOrder.BIG_ENDIAN : ByteOrder.LITTLE_ENDIAN);

                    int count = fatReader.readInt32();
                    for (int i = 0; i < count; i++) {
                        // read FatArch struct
                        /* int cputype = */ fatReader.readInt32();
                        /*int cpusubtype = */ fatReader.readInt32();
                        int offset = fatReader.readInt32();
                        int size = fatReader.readInt32();
                        /* int align = */ fatReader.readInt32();

                        // handle slice
                        rootReader.setPosition(offset);
                        FileByteReader sliceReader = rootReader.slice();
                        sliceReader.setOrder(ByteOrder.BIG_ENDIAN);
                        sliceReader.setLimit(size);
                        int sliceMagic = sliceReader.readInt32();
                        fixVersionInSlice(sliceReader, sliceMagic, currentV, compatV);
                    }
                } else {
                    fixVersionInSlice(rootReader, magic, currentV, compatV);
                }
            } catch (Throwable e) {
                throw new MachOException("Failed to handle mach-o file", e);
            }
        }

        public void close() throws IOException {
            rootReader.close();
        }

        private void fixVersionInSlice(FileByteReader reader, int magic, int currentV, int compatV ) throws MachOException {
            if (magic != MH_MAGIC && magic != MH_CIGAM && magic != MH_MAGIC_64 && magic != MH_CIGAM_64)
                throw new MachOException("unexpected Mach header MAGIC 0x" + Integer.toHexString(magic));

            reader.setOrder((magic == MH_MAGIC || magic == MH_MAGIC_64) ? ByteOrder.BIG_ENDIAN : ByteOrder.LITTLE_ENDIAN);
            boolean is64bit = (magic == MH_CIGAM_64 || magic == MH_MAGIC_64);

            // read mach header
            // magic already was read
            /*int cputype =*/ reader.readInt32();
            /*int cpusubtype =*/ reader.readInt32();
            /*int filetype =*/ reader.readInt32();
            int ncmds = reader.readInt32();
            /*int sizeofcmds =*/ reader.readInt32();
            /*int flags =*/ reader.readInt32();
            if (is64bit) {
                // just skip
                /*int reserved =*/ reader.readInt32();
            }

            // look through commands to find code sign
            for (int idx = 0; idx < ncmds; idx++) {
                long pos = reader.position();
                int cmd = reader.readInt32();
                int cmdSize = reader.readInt32();

                if (cmd == LC_ID_DYLIB) {
                    /*int strOffset =*/ reader.readInt32();
                    /*int ts =*/ reader.readInt32(); // timestamp

                    // fix versions
                    reader.writeInt32(currentV);
                    reader.writeInt32(compatV);

                    // done
                    break;
                }

                reader.setPosition(pos + cmdSize);
            }
        }
    }

    private static int encodedVersion(String v) {
        // version is presented as 0xAAAABBCC -> aaaaa.bbb.ccc (in decimal)
        String[] chunks = v.split("\\.");
        int res = Integer.parseInt(chunks[0]) << 16;
        if (chunks.length > 1)
            res |= Byte.parseByte(chunks[1]) << 8;
        if (chunks.length > 2)
            res |= Byte.parseByte(chunks[1]);
        return res;
    }


    public static void main(String[] args) throws IOException {
        if (args.length != 3) {
            System.out.println("Usage: ForceVersion <file or wildcard> <version> <compatVersion>");
            System.exit(-1);
        }
        File dylibFile = new File(args[0]);
        String currentV = args[1];
        String compatVersion = args[2];

        try (DirectoryStream<Path> dirStream = Files.newDirectoryStream(dylibFile.getParentFile().toPath(), dylibFile.getName()) ) {
            dirStream.forEach(path -> {
                try (SimpleMachOLoader loader = new SimpleMachOLoader(path.toFile(), true)) {
                    loader.fixVersions(encodedVersion(currentV), encodedVersion(compatVersion));
                } catch (IOException e) {
                    throw new RuntimeException(e);
                }
            });
        }
    }
}
