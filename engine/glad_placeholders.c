#include <glad/glad.h>

void viewport(GLint x, GLint y, GLsizei width, GLsizei height) {
  glViewport(x, y, width, height);
}

void clearColor(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha) {
  glClearColor(red, green, blue, alpha);
}

void clear(GLbitfield mask) { glClear(mask); }

void genBuffers(GLsizei n, GLuint *buffers) { glad_glGenBuffers(n, buffers); }

void bindBuffer(GLenum target, GLuint buffer) {
  glad_glBindBuffer(target, buffer);
}

void bufferData(GLenum target, GLsizeiptr size, const GLvoid *data,
                GLenum usage) {
  glad_glBufferData(target, size, data, usage);
}

GLuint createShader(GLenum shaderType) {
  return glad_glCreateShader(shaderType);
}

void shaderSource(GLuint shader, const GLchar *string, GLuint length) {
  glad_glShaderSource(shader, 1, &string, &length);
}

void compileShader(GLuint shader) { glad_glCompileShader(shader); }

GLuint createProgram(void) { return glad_glCreateProgram(); }

void attachShader(GLuint program, GLuint shader) {
  glad_glAttachShader(program, shader);
}

void linkProgram(GLuint program) { glad_glLinkProgram(program); }

GLint getUniformLocation(GLuint program, const GLchar *name, GLuint len) {
  return glad_glGetUniformLocation(program, name);
}

GLint getAttribLocation(GLuint program, const GLchar *name, GLuint len) {
  return glad_glGetAttribLocation(program, name);
}

void enableVertexAttribArray(GLuint index) {
  glad_glEnableVertexAttribArray(index);
}

void vertexAttribPointer(GLuint index, GLint size, GLenum type,
                         GLboolean normalized, GLsizei stride,
                         GLsizeiptr offset) {
  glad_glVertexAttribPointer(index, size, type, normalized, stride, offset);
}

void useProgram(GLuint program) { glad_glUseProgram(program); }

void uniformMatrix4fv(GLint location, GLsizei count, GLboolean transpose,
                      const GLfloat *value) {
  glad_glUniformMatrix4fv(location, count, transpose, value);
}

void drawArrays(GLenum mode, GLint first, GLsizei count) {
  glad_glDrawArrays(mode, first, count);
}
