#include <glad/glad.h>

void viewport(GLint x, GLint y, GLsizei width, GLsizei height) {
  glViewport(x, y, width, height);
}

void clearColor(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha) {
  glClearColor(red, green, blue, alpha);
}

void clear(GLbitfield mask) { glClear(mask); }

void genBuffers(GLsizei n, GLuint *buffers) {
  return glad_glGenBuffers(n, buffers);
}

void bindBuffer(GLenum target, GLuint buffer) {
  return glad_glBindBuffer(target, buffer);
}

void bufferData(GLenum target, GLsizeiptr size, const GLvoid *data,
                GLenum usage) {
  return glad_glBufferData(target, size, data, usage);
}
