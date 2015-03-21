// Written in the D programming language

/**
 * $(RED Warning: This application is highly experimental.)
 */

/*
 * Android backup to tarball
 * Copyright (c) 2015 by Hugo Florentino
 * Distributed under the Boost 1.0 license
 */

import std.stdio;
import std.file: write, append, exists, isFile;
import std.path: absolutePath, baseName, buildNormalizedPath, dirName;

version(Windows) {
   extern(Windows) int SetConsoleOutputCP(uint wCodePageID);
}

static immutable string appname = "ab2tgz";
static immutable string appversion = "Android backup to tarball (version 0.1.0)";
static immutable string copyright = "Copyright (c) 2015 by Hugo Florentino";
static immutable string invalidfile = "The file does not exist or is not a valid Android backup file.";
static immutable string errormessage = "Could not produce the tarball.\nApplication will now exit.";
static immutable string successmessage = "Tarball produced successfully.";
static immutable ubyte[8] tarballheader = [0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00];

void printusage() {
   writefln("\n%s\n%s\n", appversion, copyright);
   writefln("Usage:\n%s filepath.ab", appname);
}

bool producetarball(string filepath) {
   if (exists(filepath)) {
      if (!isFile(filepath)) {
         writeln(invalidfile);
         return false;
      }
   }
   else {
      writeln(invalidfile);
      return false;
   }
   
   bool successfulcreation = false;

   auto originalfile = File(filepath);
   auto filesize = originalfile.size;
   debug writefln("File size: %s", filesize);
   if (filesize < 25) {
      writeln(invalidfile);
      return false;
   }

   string defaultdir = buildNormalizedPath(dirName(filepath));
   string newfilename = buildNormalizedPath(defaultdir, baseName(filepath, ".ab") ~ ".tgz");
   debug writefln(`Tarball filename: "%s"`, newfilename);

   try {
      write(newfilename, tarballheader);
      bool isfirstiteration = true;
      foreach(ubyte[] buffer; originalfile.byChunk(64 * 1024)) {
         if (isfirstiteration) {
            append(newfilename, buffer[24..$]);
            isfirstiteration = false;
         } else {
            append(newfilename, buffer);
         } // if
      } // foreach
      if (originalfile.isOpen) {
         originalfile.close();
      }
      successfulcreation = true;
   }
   catch (Exception e) {
      writefln("Error: %s", e);
      return false;
   }
   
   return successfulcreation;
}

int main(string[] args) {
   string originalfilename;

   version(Windows) SetConsoleOutputCP(65001);
   
   switch(args.length) {
      case 2: {
         if (args[1] != "--help")
         {
            originalfilename = buildNormalizedPath(absolutePath(args[1]));
            debug writefln(`Android backup filename: "%s"`, originalfilename);
            break;
         }
      }
      default: {
         printusage;
         return -1;
      }
   }
   
   if (producetarball(originalfilename)) {
      writeln(successmessage);
   }
   else {
      writeln(errormessage);
      return -1;
   }
   return 0;
}

