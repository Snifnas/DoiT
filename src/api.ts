import { createClient } from '@supabase/supabase-js';

export const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL || '',
  import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || '',
  { auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true } }
);
export const TAGS: [string,string][] = [
 ['oven','No oven / baking'],['kitchen','No kitchen access'],['outdoors','No outdoor activities'],
 ['exercise','Avoid physical exercise'],['computer','No computer'],['internet','No internet'],
 ['tools','No DIY equipment'],['plant','No plants / gardening'],['camera','No camera equipment'],
 ['friend','Cannot involve another person'],['device','No personal device']
];
export const CATEGORY_ICON: Record<string,string> = {
 Cooking:'🍳', Creativity:'✏️', Knowledge:'🧠', Physical:'💪',
 'Practical Life':'🛠️', Social:'🤝', Outdoors:'🌿', Technology:'💻'
};
export const BADGES: Record<string,{name:string,description:string,icon:string}>={
 first_steps:{name:'First Steps',description:'Complete your first quest',icon:'🌱'},
 quest_10:{name:'Getting Started',description:'Complete 10 quests',icon:'⭐'},
 quest_25:{name:'Adventurer',description:'Complete 25 quests',icon:'🧭'},
 quest_100:{name:'Century Club',description:'Complete 100 quests',icon:'🏆'},
 streak_7:{name:'One Whole Week',description:'Reach a 7-day streak',icon:'🔥'}
};
export function levelOf(xp:number,scale=100){return Math.max(1,Math.floor(Math.sqrt(Math.max(0,xp)/scale))+1)}
export function levelProgress(xp:number,scale=100){const l=levelOf(xp,scale);const lo=scale*(l-1)**2,hi=scale*l*l;return Math.min(100,Math.round((xp-lo)/(hi-lo)*100))}
export function questXp(minutes:number,difficulty:string){const mult=difficulty==='easy'?1:difficulty==='medium'?1.25:1.5;return Math.max(10,Math.round((10+1.5*minutes)*mult/5)*5)}
export async function compressPhoto(file:File):Promise<Blob>{
 const bitmap=await createImageBitmap(file);
 const max=1600,ratio=Math.min(1,max/Math.max(bitmap.width,bitmap.height));
 const canvas=document.createElement('canvas');canvas.width=Math.round(bitmap.width*ratio);canvas.height=Math.round(bitmap.height*ratio);
 const ctx=canvas.getContext('2d');if(!ctx)throw new Error('Cannot process image');
 ctx.drawImage(bitmap,0,0,canvas.width,canvas.height);bitmap.close();
 return await new Promise<Blob>((resolve,reject)=>canvas.toBlob(blob=>blob?resolve(blob):reject(new Error('Cannot compress image')),'image/jpeg',0.78));
}
export function dateLabel(){return new Intl.DateTimeFormat('en-GB',{weekday:'long',month:'long',day:'numeric',timeZone:'Europe/Lisbon'}).format(new Date())}
export function timeLabel(iso:string){return new Intl.DateTimeFormat('en-GB',{hour:'2-digit',minute:'2-digit',timeZone:'Europe/Lisbon'}).format(new Date(iso))}
