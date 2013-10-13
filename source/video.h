#ifndef VIDEO_H
#define VIDEO_H

int video_set_scale (int mode);
void video_draw ();
void video_init ();

void video_save (FILE *f);
void video_load (FILE *f); 

#endif
