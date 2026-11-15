import React, {useEffect,useMemo,useRef,useState} from 'react';
import {
 ArrowRight,ArrowLeft,Check,CheckCircle2,ChevronDown,ChevronRight,Camera,Coins,Compass,
 Flame,Heart,MessageCircle,Users,UserRound,LayoutGrid,Trophy,Plus,RefreshCw,
 LogOut,Settings,Bell,ShieldCheck,Lock,Copy,X,Clock,BookOpen,Gift,Sparkles,
 Edit3,Send,Image as ImageIcon,Leaf,Menu,Trash2,ExternalLink,Star,MoreHorizontal
} from 'lucide-react';
import {supabase,TAGS,CATEGORY_ICON,BADGES,levelOf,levelProgress,questXp,compressPhoto,dateLabel,timeLabel} from './api';

type Tab='today'|'friends'|'skills'|'rewards'|'profile';
type Group={id:string;name:string;owner_id:string;invite_code:string;blocked_tags:string[];role?:string};
type Quest={id:string;title:string;description:string;difficulty:string;minutes:number;xp:number;skill_key:string;tags:string[];group_id?:string;active:boolean};
type Daily={slot:number;quest:Quest;done?:any;swap?:boolean};
type Feed={id:string;user_id:string;group_id:string;day:string;slot:number;quest_id:string;photo_path:string;xp_awarded:number;created_at:string;name?:string;quest?:Quest;url?:string};
const TABS:{id:Tab;label:string;icon:any}[]=[
 {id:'today',label:'Today',icon:Compass},{id:'friends',label:'Friends',icon:Users},
 {id:'skills',label:'Skills',icon:LayoutGrid},{id:'rewards',label:'Rewards',icon:Trophy},{id:'profile',label:'Profile',icon:UserRound}
];
const difficultyLabel:{[x:string]:string}={easy:'Easy',medium:'Medium',hard:'Hard'};
function Pill({children,kind='soft'}:{children:any;kind?:string}){return <span className={'pill pill-'+kind}>{children}</span>}
function Progress({value}:{value:number}){return <div className="progress"><div style={{width:value+'%'}}/></div>}
function Empty({icon:Icon=Compass,title,description}:{icon?:any;title:string;description:string}){return <div className="empty"><span className="empty-icon"><Icon size={25}/></span><h3>{title}</h3><p>{description}</p></div>}
function Modal({title,children,onClose}:{title:string;children:any;onClose:()=>void}){return <div className="modal-shade" onMouseDown={onClose}><div className="modal-panel" onMouseDown={e=>e.stopPropagation()} role="dialog" aria-modal="true"><div className="modal-top"><h2>{title}</h2><button className="icon-btn" onClick={onClose} aria-label="Close"><X size={20}/></button></div>{children}</div></div>}
function AuthScreen({onError}:{onError:(t:string)=>void}){
 const[email,setEmail]=useState('');const[password,setPassword]=useState('');const[name,setName]=useState('');const[signUp,setSignUp]=useState(false);const[working,setWorking]=useState(false);const[notice,setNotice]=useState('');
 async function submit(e:React.FormEvent){e.preventDefault();setWorking(true);setNotice('');
  const result=signUp?await supabase.auth.signUp({email,password,options:{data:{name},emailRedirectTo:window.location.origin}}):await supabase.auth.signInWithPassword({email,password});
  setWorking(false);if(result.error){onError(result.error.message);return}
  if(signUp&&!result.data.session)setNotice('Account created. Check your email for a confirmation link. If the link opens another app, return here and sign in after confirming.');
 }
 return <div className="auth-layout"><div className="auth-showcase"><div className="auth-brand"><span className="logo-mark"><Check size={22} strokeWidth={3}/></span><span>DoiT<span className="brand-dot">.</span></span></div><div className="auth-copy"><div className="eyebrow light">A LITTLE ADVENTURE, EVERY DAY</div><h1>Make today<br/><em>interesting.</em></h1><p>Three daily quests. A world of skills to discover. Better with friends.</p><div className="auth-sample"><span>✦</span><span>Try something new today</span><ArrowRight size={18}/></div></div><div className="auth-footer">REAL LIFE IS THE GAME.</div></div>
 <div className="auth-form-wrap"><div className="auth-form"><div className="mobile-auth-logo"><span className="logo-mark"><Check size={19}/></span> DoiT.</div><div className="eyebrow">YOUR ADVENTURE BEGINS HERE</div><h2>{signUp?'Create your account':'Welcome back'}</h2><p className="muted">Sign in to see today's quests and what your friends have been up to.</p>
 <form onSubmit={submit}>{signUp&&<label>Display name<input required maxLength={40} value={name} onChange={e=>setName(e.target.value)} placeholder="What should we call you?"/></label>}<label>Email address<input type="email" required value={email} onChange={e=>setEmail(e.target.value)} placeholder="you@example.com" autoComplete="email"/></label><label>Password<input type="password" minLength={6} required value={password} onChange={e=>setPassword(e.target.value)} placeholder="At least 6 characters" autoComplete={signUp?'new-password':'current-password'}/></label><button className="btn btn-primary full" disabled={working} type="submit">{working?'Working…':signUp?'Create account':'Sign in'}<ArrowRight size={17}/></button></form>
 {notice&&<p className="notice">{notice}</p>}<p className="auth-switch">{signUp?'Already have an account?':'New here?'} <button className="text-action" onClick={()=>{setSignUp(!signUp);setNotice('')}}>{signUp?'Sign in':'Create an account'}</button></p>
 <p className="footnote"><Lock size={13}/> Private groups · Photos only shared with your group</p></div></div></div>;
}
export default function App(){
 const[user,setUser]=useState<any>(null);const[checking,setChecking]=useState(true);const[profile,setProfile]=useState<any>(null);
 const[groups,setGroups]=useState<Group[]>([]);const[activeId,setActiveId]=useState('');const[tab,setTab]=useState<Tab>('today');
 const[daily,setDaily]=useState<Daily[]>([]);const[day,setDay]=useState('');const[primarySlot,setPrimarySlot]=useState(0);const[feed,setFeed]=useState<Feed[]>([]);
 const[skills,setSkills]=useState<any[]>([]);const[ledger,setLedger]=useState<any[]>([]);const[awards,setAwards]=useState<any[]>([]);
 const[shop,setShop]=useState<any[]>([]);const[owned,setOwned]=useState<any[]>([]);const[alerts,setAlerts]=useState<any[]>([]);
 const[comments,setComments]=useState<any[]>([]);const[reactions,setReactions]=useState<any[]>([]);
 const[loading,setLoading]=useState(false);const[busy,setBusy]=useState('');const[error,setError]=useState('');const[toast,setToast]=useState('');
 const[modal,setModal]=useState('');const[showAlerts,setShowAlerts]=useState(false);
 const[groupName,setGroupName]=useState('');const[invite,setInvite]=useState('');const[photoZoom,setPhotoZoom]=useState('');
 const[commentDraft,setCommentDraft]=useState<Record<string,string>>({});
 const[questForm,setQuestForm]=useState({title:'',description:'',skill_key:'cooking',difficulty:'easy',minutes:15,tags:[] as string[]});
 const fileInputs=useRef<Record<number,HTMLInputElement|null>>({});
 const currentGroup=groups.find(g=>g.id===activeId);
 const me=user?.id||'';
 const isOwner=currentGroup?.owner_id===me;
 function notify(message:string){setToast(message);window.setTimeout(()=>setToast(''),4600)}
 function fail(message:string){setError(message);window.setTimeout(()=>setError(''),8500)}
 useEffect(()=>{let mounted=true;supabase.auth.getSession().then(({data})=>{if(mounted){setUser(data.session?.user||null);setChecking(false)}}).catch(e=>{fail(e.message);setChecking(false)});
 const {data:{subscription}}=supabase.auth.onAuthStateChange((_event,session)=>{setUser(session?.user||null);setChecking(false)});
 return()=>{mounted=false;subscription.unsubscribe()}},[]);
 useEffect(()=>{if(!me){setProfile(null);setGroups([]);setActiveId('');return}bootstrap()},[me]);
 useEffect(()=>{const params=new URLSearchParams(window.location.search);const code=params.get('invite')||localStorage.getItem('doit-invite');if(code){setInvite(code.toUpperCase());if(me){setModal('join')}else{localStorage.setItem('doit-invite',code)}}},[me]);
 async function bootstrap(){
  setLoading(true);
  try{
   const p=await supabase.rpc('doit_ensure_profile',{p_name:user?.user_metadata?.name||user?.email?.split('@')[0]||'Adventurer'});
   if(p.error)throw p.error;setProfile(p.data);
   const memberships=await supabase.from('doit_members').select('group_id,role').eq('user_id',me);
   if(memberships.error)throw memberships.error;
   const ids=(memberships.data||[]).map((m:any)=>m.group_id);
   let groupList:Group[]=[];
   if(ids.length){const g=await supabase.from('doit_groups').select('*').in('id',ids);if(g.error)throw g.error;groupList=(g.data||[]).map((row:any)=>({...row,role:(memberships.data||[]).find((m:any)=>m.group_id===row.id)?.role}));}
   setGroups(groupList);
   const last=window.localStorage.getItem('doit-group-'+me);
   setActiveId(prev=>groupList.some(g=>g.id===prev)?prev:groupList.some(g=>g.id===last)?last||'':(groupList[0]?.id||''));
   await loadPersonal();
  }catch(e:any){fail(e.message||'Could not initialize the app')}finally{setLoading(false)}
 }
 async function loadPersonal(){
  const [p,s,l,a,sh,o,al]=await Promise.all([
   supabase.from('doit_profiles').select('*').eq('id',me).single(),
   supabase.from('doit_skills').select('*').order('category').order('name'),
   supabase.from('doit_xp_ledger').select('xp,skill_key,source').eq('user_id',me),
   supabase.from('doit_achievements').select('*').eq('user_id',me),
   supabase.from('doit_shop').select('*').order('price'),
   supabase.from('doit_owned').select('*').eq('user_id',me),
   supabase.from('doit_alerts').select('*').eq('user_id',me).order('created_at',{ascending:false}).limit(30)
  ]);
  if(p.data)setProfile(p.data);if(s.data)setSkills(s.data);if(l.data)setLedger(l.data);
  if(a.data)setAwards(a.data);if(sh.data)setShop(sh.data);if(o.data)setOwned(o.data);if(al.data)setAlerts(al.data);
 }
 useEffect(()=>{if(!activeId||!me)return;window.localStorage.setItem('doit-group-'+me,activeId);loadGroup(activeId)},[activeId,me]);
 useEffect(()=>{function onVisible(){if(document.visibilityState==='visible'&&activeId){loadGroup(activeId);loadPersonal()}}document.addEventListener('visibilitychange',onVisible);return()=>document.removeEventListener('visibilitychange',onVisible)},[activeId,me]);
 async function loadGroup(groupId:string){
  if(!groupId||!me)return;
  setLoading(true);
  try{
   const prepared=await supabase.rpc('doit_prepare_daily',{p_group:groupId});
   if(prepared.error)throw prepared.error;
   const today=prepared.data as string;setDay(today);
   const [slots,swaps,done,history,primary]=await Promise.all([
    supabase.from('doit_daily').select('slot,quest_id').eq('group_id',groupId).eq('day',today).order('slot'),
    supabase.from('doit_swaps').select('slot,quest_id').eq('group_id',groupId).eq('day',today).eq('user_id',me),
    supabase.from('doit_completions').select('*').eq('group_id',groupId).eq('day',today).eq('user_id',me),
    supabase.from('doit_completions').select('*').eq('group_id',groupId).order('created_at',{ascending:false}).limit(60),
    supabase.from('doit_primary').select('slot').eq('group_id',groupId).eq('day',today).eq('user_id',me).maybeSingle()
   ]);
   setPrimarySlot(primary.data?.slot||0);
   for(const result of [slots,swaps,done,history])if(result.error)throw result.error;
   const qs=new Set<string>();
   (slots.data||[]).forEach((s:any)=>qs.add(s.quest_id));
   (swaps.data||[]).forEach((s:any)=>qs.add(s.quest_id));
   (history.data||[]).forEach((s:any)=>qs.add(s.quest_id));
   const ids=[...qs];
   const questResult=ids.length?await supabase.from('doit_quests').select('*').in('id',ids):{data:[],error:null};
   if(questResult.error)throw questResult.error;
   const qmap=new Map((questResult.data||[]).map((q:any)=>[q.id,q]));
   const resolved=(slots.data||[]).map((s:any)=>{
    const swap=(swaps.data||[]).find((x:any)=>x.slot===s.slot);
    return {slot:s.slot,quest:qmap.get(swap?.quest_id||s.quest_id),swap:!!swap,done:(done.data||[]).find((x:any)=>x.slot===s.slot)};
   }).filter((x:any)=>!!x.quest) as Daily[];
   setDaily(resolved);
   const rows=(history.data||[]) as Feed[];
   const authorIds=[...new Set(rows.map(r=>r.user_id))];
   const people=authorIds.length?await supabase.from('doit_profiles').select('id,display_name,equipped_frame').in('id',authorIds):{data:[]};
   const names=new Map((people.data||[]).map((p:any)=>[p.id,p.display_name]));
   const paths=rows.map(r=>r.photo_path);
   const urls=paths.length?await supabase.storage.from('doit-photos').createSignedUrls(paths,3600):{data:[],error:null};
   const signed=new Map((urls.data||[]).map((item:any)=>[item.path||item.signedUrl?.split('/sign/doit-photos/')[1]?.split('?')[0],item.signedUrl]));
   setFeed(rows.map(r=>({...r,name:names.get(r.user_id)||'Adventurer',quest:qmap.get(r.quest_id),url:signed.get(r.photo_path)||''})));
   const completionIds=rows.map(r=>r.id);
   if(completionIds.length){
    const [cs,rs]=await Promise.all([supabase.from('doit_comments').select('*').in('completion_id',completionIds).order('created_at'),supabase.from('doit_reactions').select('*').in('completion_id',completionIds)]);
    setComments(cs.data||[]);setReactions(rs.data||[]);
   }else{setComments([]);setReactions([])}
  }catch(e:any){fail(e.message||'Could not load quests')}finally{setLoading(false)}
 }
 async function makeGroup(){
  if(!groupName.trim())return;setBusy('group');
  const r=await supabase.rpc('doit_create_group',{p_name:groupName.trim(),p_tags:[]});
  setBusy('');if(r.error)return fail(r.error.message);
  setGroupName('');setModal('');await bootstrap();setActiveId(r.data);notify('Your group is ready. Invite your friends!');
 }
 async function joinGroup(){
  if(!invite.trim())return;setBusy('join');
  const r=await supabase.rpc('doit_join_group',{p_code:invite.trim()});
  setBusy('');if(r.error)return fail(r.error.message);
  setInvite('');localStorage.removeItem('doit-invite');window.history.replaceState({},'',window.location.pathname);setModal('');await bootstrap();setActiveId(r.data);notify('Welcome to the group!');
 }
 async function choosePrimary(slot:number){if(!activeId)return;setBusy('main-'+slot);const r=await supabase.rpc('doit_choose_primary',{p_group:activeId,p_slot:slot});setBusy('');if(r.error)return fail(r.error.message);setPrimarySlot(slot);notify('Main quest selected! You can still complete all three.')}
 async function swapQuest(slot:number){if(!activeId)return;setBusy('swap-'+slot);
  const r=await supabase.rpc('doit_swap_quest',{p_group:activeId,p_slot:slot});setBusy('');
  if(r.error)return fail(r.error.message);
  notify('A new quest has appeared');await Promise.all([loadGroup(activeId),loadPersonal()]);
 }
 async function submitPhoto(slot:number,file:File){
  if(!file||!activeId||!me)return;
  setBusy('photo-'+slot);
  let path='';
  try{
   if(file.size>15000000)throw new Error('Please choose an image under 15 MB.');
   const blob=await compressPhoto(file);
   path=activeId+'/'+me+'/'+crypto.randomUUID()+'.jpg';
   const uploaded=await supabase.storage.from('doit-photos').upload(path,blob,{contentType:'image/jpeg',upsert:false});
   if(uploaded.error)throw uploaded.error;
   const result=await supabase.rpc('doit_complete',{p_group:activeId,p_slot:slot,p_photo:path});
   if(result.error){await supabase.storage.from('doit-photos').remove([path]);throw result.error}
   notify('Quest complete! +'+result.data.xp+' XP'+(result.data.bonus?' · +'+result.data.bonus+' daily bonus':''));
   await Promise.all([loadGroup(activeId),loadPersonal()]);
  }catch(e:any){fail(e.message||'Photo upload failed')}finally{setBusy('');if(fileInputs.current[slot])fileInputs.current[slot]!.value=''}
 }
 async function reactTo(item:Feed,emoji:string){
  const existing=reactions.find(x=>x.completion_id===item.id&&x.user_id===me);
  let r:any;
  if(existing?.emoji===emoji)r=await supabase.from('doit_reactions').delete().eq('completion_id',item.id).eq('user_id',me);
  else r=await supabase.from('doit_reactions').upsert({completion_id:item.id,user_id:me,emoji});
  if(r.error)return fail(r.error.message);await loadGroup(activeId);
 }
 async function commentOn(id:string){
  const body=(commentDraft[id]||'').trim();if(!body)return;
  const r=await supabase.from('doit_comments').insert({completion_id:id,user_id:me,body});
  if(r.error)return fail(r.error.message);setCommentDraft(p=>({...p,[id]:''}));await loadGroup(activeId);
 }
 async function buy(item:any){setBusy('buy-'+item.id);const r=await supabase.rpc('doit_buy',{p_item:item.id});setBusy('');
  if(r.error)return fail(r.error.message);notify(item.title+' unlocked!');loadPersonal();
 }
 async function equip(item:any){const r=await supabase.rpc('doit_equip',{p_item:item.id});
  if(r.error)return fail(r.error.message);notify(item.title+' equipped');loadPersonal();
 }
 async function saveProfile(){setBusy('profile');
  const r=await supabase.from('doit_profiles').update({display_name:profile.display_name,blocked_tags:profile.blocked_tags}).eq('id',me);
  setBusy('');if(r.error)return fail(r.error.message);notify('Preferences saved');loadPersonal();
 }
 async function saveGroupPrefs(tags:string[]){if(!isOwner)return;const r=await supabase.from('doit_groups').update({blocked_tags:tags}).eq('id',activeId);
  if(r.error)return fail(r.error.message);setGroups(gs=>gs.map(g=>g.id===activeId?{...g,blocked_tags:tags}:g));notify('Group restrictions saved. They apply to future daily quests.');
 }
 async function saveQuest(){
  if(!questForm.title.trim()||!questForm.description.trim())return fail('A title and instructions are required');
  setBusy('quest');
  const r=await supabase.from('doit_quests').insert({title:questForm.title.trim(),description:questForm.description.trim(),skill_key:questForm.skill_key,difficulty:questForm.difficulty,minutes:questForm.minutes,xp:questXp(questForm.minutes,questForm.difficulty),tags:questForm.tags,group_id:activeId,created_by:me,active:true});
  setBusy('');if(r.error)return fail(r.error.message);
  setQuestForm({title:'',description:'',skill_key:'cooking',difficulty:'easy',minutes:15,tags:[]});notify('Custom group quest saved to the library');
 }
 async function deactivateQuest(id:string){const r=await supabase.from('doit_quests').update({active:false}).eq('id',id);if(r.error)return fail(r.error.message);notify('Quest deactivated');loadAdminQuests()}
 const[adminQuests,setAdminQuests]=useState<any[]>([]);
 async function loadAdminQuests(){if(!activeId)return;const r=await supabase.from('doit_quests').select('*').eq('group_id',activeId).order('created_at',{ascending:false});if(r.data)setAdminQuests(r.data)}
 useEffect(()=>{if(tab==='profile'&&isOwner)loadAdminQuests()},[tab,activeId,isOwner]);
 const stat=useMemo(()=>{const dict:Record<string,number>={};for(const row of ledger)if(row.skill_key)dict[row.skill_key]=(dict[row.skill_key]||0)+row.xp;return dict},[ledger]);
 const completeCount=daily.filter(q=>q.done).length;
 const categories=useMemo(()=>[...new Set(skills.map(x=>x.category))],[skills]);
 const latestUnread=alerts.filter(a=>!a.read_at).length;
 const unread=latestUnread>9?'9+':latestUnread;
 const accountLevel=levelOf(profile?.xp||0,140);
 function TagPicker({value,onChange}:{value:string[];onChange:(v:string[])=>void}){return <div className="tag-grid">{TAGS.map(([key,label])=><label className={'tag-choice '+(value?.includes(key)?'chosen':'')} key={key}><input type="checkbox" checked={value?.includes(key)||false} onChange={e=>onChange(e.target.checked?[...(value||[]),key]:(value||[]).filter(t=>t!==key))}/><span>{label}</span>{value?.includes(key)&&<Check size={14}/>}</label>)}</div>}
 if(checking)return <div className="launch"><span className="logo-mark"><Check/></span><p>Getting your adventure ready...</p></div>;
 if(!user)return <><AuthScreen onError={fail}/>{error&&<div className="global-toast error-toast">{error}</div>}</>;
 if(!profile&&loading)return <div className="launch"><span className="logo-mark"><Check/></span><p>Loading your adventure...</p></div>;
 const frameStyle=profile?.equipped_frame?'avatar-frame '+profile.equipped_frame:'avatar-frame';
 return <div className={'app-shell '+(profile?.equipped_theme||'')}>
  <header className="topbar"><div className="topbar-inner">
   <button className="brand" onClick={()=>setTab('today')}><span className="logo-mark"><Check size={19} strokeWidth={3}/></span><span>DoiT<span className="brand-dot">.</span></span></button>
   <div className="header-group">{groups.length>0&&<div className="group-select"><Users size={16}/><select aria-label="Select group" value={activeId} onChange={e=>{setActiveId(e.target.value);setTab('today')}}>{groups.map(g=><option key={g.id} value={g.id}>{g.name}</option>)}</select><ChevronDown size={15}/></div>}<button className="icon-btn" onClick={()=>setModal('join')} aria-label="Join group"><Plus size={19}/></button></div>
   <div className="header-actions"><div className="coin-chip"><Coins size={16}/><strong>{profile?.coins||0}</strong></div><div className="notification-wrap"><button className="icon-btn" onClick={()=>setShowAlerts(!showAlerts)} aria-label="Notifications"><Bell size={19}/>{latestUnread>0&&<i className="notif-dot">{unread}</i>}</button>{showAlerts&&<div className="notifications-pop"><h3>Notifications</h3>{alerts.length?alerts.slice(0,12).map(a=><p className={!a.read_at?'unread':''} key={a.id}>{a.text}<span>{timeLabel(a.created_at)}</span></p>):<p>Nothing new yet.</p>}<button className="text-action" onClick={async()=>{await supabase.from('doit_alerts').update({read_at:new Date().toISOString()}).eq('user_id',me).is('read_at',null);setShowAlerts(false);loadPersonal()}}>Mark all as read</button></div>}</div><button className={frameStyle+' mini-avatar'} onClick={()=>setTab('profile')} title="Your profile">{(profile?.display_name||'A')[0].toUpperCase()}</button></div>
  </div></header>
  <div className="main-layout"><aside className="side-nav"><div className="nav-caption">YOUR ADVENTURE</div>{TABS.map(item=><button key={item.id} className={'side-link '+(tab===item.id?'active':'')} onClick={()=>setTab(item.id)}><item.icon size={19}/>{item.label}{item.id==='friends'&&feed.length>0&&<span className="nav-count">{Math.min(feed.length,99)}</span>}</button>)}<div className="side-divider"/><div className="sidebar-card"><div className="sidebar-star"><Sparkles size={20}/></div><h4>Little steps. Big stories.</h4><p>There is always something worth discovering.</p></div><div className="sidebar-bottom">ONE NEW THING EVERY DAY</div></aside>
  <main className="main-content">
   {!activeId?<div className="welcome-panel"><div className="welcome-icon"><Compass size={30}/></div><div className="eyebrow">THE ADVENTURE STARTS TOGETHER</div><h1>Everything starts with a group.</h1><p>Create a private circle for your friends or join one using an invite code. Everyone gets the same three quests each day.</p><div className="welcome-actions"><button className="btn btn-primary" onClick={()=>setModal('create')}><Plus size={18}/> Create a group</button><button className="btn btn-outline" onClick={()=>setModal('join')}>Join with a code <ArrowRight size={17}/></button></div></div>:
   <>
    {tab==='today'&&<section className="page-enter">
     <div className="section-heading"><div><div className="eyebrow">{dateLabel().toUpperCase()} · DAILY QUESTS</div><h1>Make today <em>interesting.</em></h1><p>Three little invitations to do something different. Pick one, or take on all three.</p></div><div className="date-stamp"><span>{completeCount}/3</span><small>COMPLETE</small></div></div>
     <div className="daily-progress"><span><Sparkles size={16}/> Today's progress</span><Progress value={completeCount/3*100}/><strong>{completeCount===3?'All done!':completeCount+' of 3'}</strong></div>
     <div className="quest-stack">
     {daily.map(({slot,quest,done,swap})=><article key={slot} className={'quest-card '+(done?'finished':'')}>
       <div className={'quest-decor '+quest.difficulty}><div className="quest-number">0{slot}</div><div className="quest-symbol">{quest.difficulty==='easy'?'✳':quest.difficulty==='medium'?'◈':'✦'}</div></div>
       <div className="quest-body"><div className="quest-meta"><Pill kind={quest.difficulty}>{difficultyLabel[quest.difficulty]}</Pill><span className="dot-sep">·</span><span>{skills.find(s=>s.key===quest.skill_key)?.name||quest.skill_key}</span>{primarySlot===slot&&<Pill kind="primary">Your main quest</Pill>}</div><h2>{quest.title}</h2><p>{quest.description}</p><div className="quest-facts"><span><Clock size={14}/>{quest.minutes} min</span><span><Sparkles size={14}/>{quest.xp} XP</span></div></div>
       <div className="quest-actions">{done?<div className="done-label"><CheckCircle2 size={21}/><span>Completed</span><small>+{done.xp_awarded} XP</small></div>:!primarySlot?<button className="btn btn-primary" disabled={!!busy} onClick={()=>choosePrimary(slot)}><Check size={17}/> Choose this quest</button>:<><label className={'btn btn-primary quest-submit '+(busy==='photo-'+slot?'disabled':'')}><Camera size={17}/>{busy==='photo-'+slot?'Uploading…':'Complete with photo'}<input type="file" accept="image/*" aria-label={'Upload photo for '+quest.title} disabled={!!busy} ref={el=>{fileInputs.current[slot]=el}} onChange={e=>{if(e.target.files?.[0])submitPhoto(slot,e.target.files[0])}}/></label><button className="quest-reroll" disabled={!!busy||!!swap} onClick={()=>swapQuest(slot)} title={swap?'Already replaced today':'Replace quest'}><RefreshCw size={14}/>{swap?'Replaced':'Replace'}</button>{!completeCount&&primarySlot!==slot&&<button className="quest-reroll" onClick={()=>choosePrimary(slot)}><Star size={14}/> Make main</button>}</>}</div>
       {feed.some(f=>f.day===day&&f.slot===slot)&&<div className="quest-peers"><div className="peer-avatars">{feed.filter(f=>f.day===day&&f.slot===slot).slice(0,5).map(f=><span key={f.id} title={f.name}>{(f.name||'A')[0].toUpperCase()}</span>)}</div><span>{feed.filter(f=>f.day===day&&f.slot===slot).length} completed in your group</span><button className="text-action" onClick={()=>setTab('friends')}>View photos <ArrowRight size={13}/></button></div>}
      </article>)}
     {!loading&&daily.length===0&&<Empty title="No quests available yet" description="Ask the group owner to adjust restrictions or add more quests to the library."/>}
     </div>
     <div className="bonus-strip"><div className="bonus-icon"><Gift size={20}/></div><div><strong>Going for all three?</strong><p>Finish every quest today to earn an extra 20% XP and 30 coins.</p></div><span>{completeCount===3?'Unlocked ✨':'DAILY BONUS'}</span></div>
    </section>}
    {tab==='friends'&&<section className="page-enter"><div className="section-heading"><div><div className="eyebrow">SHARED ADVENTURES</div><h1>Friends <em>& stories.</em></h1><p>Every photo tells a story. Here's what your group has been up to.</p></div><button className="btn btn-outline refresh" onClick={()=>loadGroup(activeId)}><RefreshCw size={16}/> Refresh</button></div>
     <div className="feed-tabs"><span className="active">Activity feed</span><span>{feed.length} recent completions</span></div>
     {feed.length===0?<Empty icon={Users} title="No stories yet" description="Be the first to complete a quest. Your photo will show up here for your friends."/>:
     <div className="feed-list">{feed.map(f=><article className="feed-card" key={f.id}><div className="feed-author"><span className="feed-avatar">{(f.name||'A')[0].toUpperCase()}</span><div><strong>{f.name}</strong><p>Completed a {f.quest?.difficulty||'daily'} quest · {timeLabel(f.created_at)}</p></div><span className="feed-xp">+{f.xp_awarded} XP</span></div><h3>{f.quest?.title||'Daily quest'}</h3>{f.url?<button className="feed-photo" onClick={()=>setPhotoZoom(f.url||'')}><img src={f.url} alt={'Photo proof for '+(f.quest?.title||'quest')}/></button>:<div className="photo-missing"><ImageIcon size={25}/>Photo temporarily unavailable</div>}
      <div className="feed-social"><div className="reaction-row">{['🔥','👏','❤️','😂'].map(emoji=><button key={emoji} className={reactions.some(r=>r.completion_id===f.id&&r.user_id===me&&r.emoji===emoji)?'selected':''} onClick={()=>reactTo(f,emoji)}>{emoji}<span>{reactions.filter(r=>r.completion_id===f.id&&r.emoji===emoji).length||''}</span></button>)}</div><span><MessageCircle size={15}/>{comments.filter(c=>c.completion_id===f.id).length}</span></div>
      {comments.filter(c=>c.completion_id===f.id).map(c=><div className="comment" key={c.id}><strong>{c.user_id===me?'You':feed.find(x=>x.user_id===c.user_id)?.name||'Friend'}</strong> {c.body}</div>)}
      <div className="comment-form"><input maxLength={400} placeholder="Leave a comment…" value={commentDraft[f.id]||''} onChange={e=>setCommentDraft(p=>({...p,[f.id]:e.target.value}))} onKeyDown={e=>{if(e.key==='Enter')commentOn(f.id)}}/><button aria-label="Send comment" disabled={!commentDraft[f.id]?.trim()} onClick={()=>commentOn(f.id)}><Send size={17}/></button></div>
     </article>)}</div>}
    </section>}
    {tab==='skills'&&<section className="page-enter"><div className="section-heading"><div><div className="eyebrow">YOUR PERSONAL PROGRESSION</div><h1>Every day, <em>a little better.</em></h1><p>Every quest builds a real-world skill. There's no race, just progress.</p></div></div>
     <div className="skill-hero"><div className="skill-hero-icon"><Sparkles size={28}/></div><div><div className="eyebrow">OVERALL LEVEL</div><h2>Level {accountLevel} Adventurer</h2><p>{(profile?.xp||0).toLocaleString()} total XP earned</p><Progress value={levelProgress(profile?.xp||0,140)}/></div><div className="hero-medal">✦</div></div>
     {categories.map(category=><div className="skill-section" key={category}><div className="skill-category-title"><span>{CATEGORY_ICON[category]||'✳'}</span><h3>{category}</h3><span>{skills.filter(x=>x.category===category).length} skills</span></div><div className="skills-grid">{skills.filter(s=>s.category===category).map(s=><div className="skill-tile" key={s.key}><div className="skill-level">{levelOf(stat[s.key]||0)}</div><div className="skill-tile-name"><strong>{s.name}</strong><span>{(stat[s.key]||0).toLocaleString()} XP</span></div><Progress value={levelProgress(stat[s.key]||0)}/></div>)}</div></div>)}
    </section>}
    {tab==='rewards'&&<section className="page-enter"><div className="section-heading"><div><div className="eyebrow">MILESTONES & COLLECTIBLES</div><h1>Little wins, <em>lasting rewards.</em></h1><p>Earn milestones and spend coins on things that make your profile yours.</p></div></div>
     <div className="reward-stats"><div><Flame size={22}/><strong>{profile?.streak||0}</strong><span>Day streak</span></div><div><Coins size={22}/><strong>{profile?.coins||0}</strong><span>Coins available</span></div><div><RefreshCw size={22}/><strong>{profile?.rerolls||0}</strong><span>Reroll tokens</span></div><div><ShieldCheck size={22}/><strong>{profile?.freezes||0}</strong><span>Streak freezes</span></div></div>
     <div className="subheading"><h2>Achievements</h2><span>{awards.length} / {Object.keys(BADGES).length} unlocked</span></div><div className="achievement-grid">{Object.entries(BADGES).map(([code,b])=><div className={'achievement '+(awards.some(a=>a.code===code)?'unlocked':'locked')} key={code}><span>{b.icon}</span><strong>{b.name}</strong><p>{b.description}</p>{awards.some(a=>a.code===code)?<small><Check size={13}/> Unlocked</small>:<small><Lock size={13}/> Locked</small>}</div>)}</div>
     <div className="subheading"><h2>Cosmetic shop</h2><span>Earned coins only. No purchases.</span></div><div className="shop-grid">{shop.map(item=>{const have=owned.some(o=>o.item_id===item.id);const equipped=(item.kind==='frame'?profile?.equipped_frame:profile?.equipped_theme)===item.id;return <div className="shop-card" key={item.id}><div className="shop-art">{item.icon}</div><strong>{item.title}</strong><p>{item.kind==='frame'?'Profile frame':'App appearance'}</p><button className={'btn '+(equipped?'btn-subtle':have?'btn-outline':'btn-primary')} disabled={!!busy||equipped||(!have&&(profile?.coins||0)<item.price)} onClick={()=>have?equip(item):buy(item)}>{equipped?'Equipped':have?'Equip':<><Coins size={15}/>{item.price} coins</>}</button></div>})}</div>
    </section>}
    {tab==='profile'&&<section className="page-enter"><div className="section-heading"><div><div className="eyebrow">YOUR CORNER</div><h1>Your <em>adventure.</em></h1><p>Make it personal. Adjust what you can do and manage your group.</p></div></div>
     <div className="profile-banner"><div className={frameStyle+' avatar-large'}>{(profile?.display_name||'A')[0].toUpperCase()}</div><div><h2>{profile?.display_name||'Adventurer'}</h2><p>Level {accountLevel} · {(profile?.xp||0).toLocaleString()} XP</p></div><button className="btn btn-outline" onClick={()=>supabase.auth.signOut()}><LogOut size={16}/> Sign out</button></div>
     <div className="settings-card"><div className="subheading compact"><h2>Personal settings</h2><span>Only you can change these</span></div><label>Display name<input maxLength={40} value={profile?.display_name||''} onChange={e=>setProfile({...profile,display_name:e.target.value})}/></label><h3>Activities I cannot do</h3><p className="small-muted">Only affects your personal replacement choices. Mark genuine limitations, not just preferences.</p><TagPicker value={profile?.blocked_tags||[]} onChange={tags=>setProfile({...profile,blocked_tags:tags})}/><button className="btn btn-primary" disabled={!!busy} onClick={saveProfile}><Check size={16}/> Save preferences</button></div>
     <div className="settings-card"><div className="subheading compact"><h2>Private group</h2><span>{currentGroup?.role==='owner'?'Owner':'Member'}</span></div><div className="group-detail"><div><span>Group name</span><strong>{currentGroup?.name}</strong></div><div><span>Invite code</span><strong className="code">{currentGroup?.invite_code}</strong></div></div><div className="action-row"><button className="btn btn-outline" onClick={async()=>{try{await navigator.clipboard.writeText(window.location.origin+'/?invite='+currentGroup?.invite_code);notify('Invitation link copied')}catch{notify('Invite code: '+currentGroup?.invite_code)}}}><Copy size={16}/> Copy invitation link</button><button className="btn btn-outline" onClick={()=>setModal('create')}><Plus size={16}/> Create another group</button></div></div>
     {isOwner&&<div className="settings-card"><div className="subheading compact"><h2>Group-wide restrictions</h2><Pill>Owner controls</Pill></div><p className="small-muted">These limitations apply to future shared quests for everyone. Today's choices remain unchanged.</p><TagPicker value={currentGroup?.blocked_tags||[]} onChange={saveGroupPrefs}/></div>}
     {isOwner&&<div className="settings-card"><div className="subheading compact"><h2>Quest library admin</h2><Pill>Owner controls</Pill></div><p className="small-muted">Add permanent quality-controlled quests to your group. The next daily reset can select them.</p><div className="admin-form"><label>Quest title<input maxLength={140} placeholder="e.g. Learn to draw a plant" value={questForm.title} onChange={e=>setQuestForm({...questForm,title:e.target.value})}/></label><label>What should the player do?<textarea rows={3} maxLength={1200} placeholder="Clear instructions and what the photo should show…" value={questForm.description} onChange={e=>setQuestForm({...questForm,description:e.target.value})}/></label><div className="form-grid"><label>Skill<select value={questForm.skill_key} onChange={e=>setQuestForm({...questForm,skill_key:e.target.value})}>{skills.map(s=><option value={s.key} key={s.key}>{s.category} · {s.name}</option>)}</select></label><label>Difficulty<select value={questForm.difficulty} onChange={e=>setQuestForm({...questForm,difficulty:e.target.value})}><option value="easy">Easy</option><option value="medium">Medium</option><option value="hard">Hard</option></select></label><label>Minutes<input type="number" min={5} max={300} value={questForm.minutes} onChange={e=>setQuestForm({...questForm,minutes:Math.max(5,Math.min(300,Number(e.target.value)||5))})}/></label><label>XP reward<input readOnly value={questXp(questForm.minutes,questForm.difficulty)}/></label></div><h3>Required resources</h3><TagPicker value={questForm.tags} onChange={tags=>setQuestForm({...questForm,tags})}/><button className="btn btn-primary" disabled={!!busy} onClick={saveQuest}><Plus size={17}/> Add quest to library</button></div>
      {adminQuests.length>0&&<><h3 className="admin-list-title">Your group quests ({adminQuests.length})</h3>{adminQuests.map(q=><div className="admin-quest" key={q.id}><div><strong>{q.title}</strong><span>{q.difficulty} · {q.xp} XP · {q.active?'Active':'Inactive'}</span></div>{q.active&&<button className="icon-btn" onClick={()=>deactivateQuest(q.id)} aria-label="Deactivate quest"><Trash2 size={17}/></button>}</div>)}</>}
     </div>}
    </section>}
   </>}
  </main>
  <aside className="right-rail"><div className="rail-card greeting"><div className="rail-avatar"><span className={frameStyle+' avatar-medium'}>{(profile?.display_name||'A')[0].toUpperCase()}</span><div><span>YOUR JOURNEY</span><strong>Level {accountLevel}</strong></div></div><Progress value={levelProgress(profile?.xp||0,140)}/><small>{(profile?.xp||0).toLocaleString()} total XP</small></div><div className="rail-card"><div className="rail-title"><Flame size={17}/> A good habit to keep</div><div className="rail-streak"><strong>{profile?.streak||0}</strong><span>day streak</span></div><p>One quest is enough to keep the momentum going.</p></div><div className="rail-card"><div className="rail-title"><Users size={17}/> Your circle</div><div className="rail-peers">{feed.filter((v,i,a)=>a.findIndex(x=>x.user_id===v.user_id)===i).slice(0,4).map(f=><div key={f.user_id}><span className="rail-peer-avatar">{(f.name||'A')[0].toUpperCase()}</span><strong>{f.name}</strong></div>)}{feed.length===0&&<p>Your friends' progress will appear here.</p>}</div></div><div className="rail-end">DO SOMETHING WORTH REMEMBERING.</div></aside>
  </div>
  <nav className="mobile-nav">{TABS.map(item=><button key={item.id} className={tab===item.id?'active':''} onClick={()=>setTab(item.id)}><item.icon size={21}/><span>{item.label}</span></button>)}</nav>
  {modal==='create'&&<Modal title="Create a private group" onClose={()=>setModal('')}><p className="muted">Everyone in your group will receive the same three quests at midnight Lisbon time.</p><label>Group name<input maxLength={64} placeholder="e.g. The Curious Ones" value={groupName} onChange={e=>setGroupName(e.target.value)} onKeyDown={e=>e.key==='Enter'&&makeGroup()}/></label><button className="btn btn-primary full" disabled={!!busy} onClick={makeGroup}><Users size={17}/> Create group</button></Modal>}
  {modal==='join'&&<Modal title="Join your friends" onClose={()=>setModal('')}><p className="muted">Ask your friend for their private invite code.</p><label>Invitation code<input className="input-code" maxLength={30} placeholder="XXXXXXXXXX" value={invite} onChange={e=>setInvite(e.target.value.toUpperCase())} onKeyDown={e=>e.key==='Enter'&&joinGroup()}/></label><button className="btn btn-primary full" disabled={!!busy} onClick={joinGroup}><ArrowRight size={17}/> Join group</button></Modal>}
  {photoZoom&&<div className="photo-overlay" onClick={()=>setPhotoZoom('')}><button aria-label="Close photo"><X size={26}/></button><img src={photoZoom} alt="Quest completion enlarged"/></div>}
  {error&&<div role="alert" className="global-toast error-toast"><X size={18}/>{error}<button onClick={()=>setError('')}>×</button></div>}
  {toast&&<div role="status" className="global-toast"><CheckCircle2 size={18}/>{toast}</div>}
 </div>;
}
