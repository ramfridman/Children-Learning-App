# A model of the E-1 rule on the engine's BKT, to compute the test vectors of docs/languages/writing-mastery.md.
CREDIT=[1.0,0.8,0.5,0.0]; PT=0.15; SLIP=0.08; GOPEN=0.02; BAR=0.95
def bkt(p, correct, w):
    if w<=0: return p
    g=GOPEN
    post = (p*(1-SLIP))/(p*(1-SLIP)+(1-p)*g) if correct else (p*SLIP)/(p*SLIP+(1-p)*(1-g))
    learned=post+(1-post)*PT
    return min(max(p+min(max(w,0),1)*(learned-p),0.001),0.999)
# items: id -> (mode, cue, group, purpose, check)
ITEMS={
 'cm':('copy',None,'m','practice',False),'cl':('copy',None,'l','practice',False),
 'ms':('memory','sound','m','practice',False),'mn':('memory','name','m','practice',False),
 'ls':('memory','sound','l','practice',False),'ln':('memory','name','l','practice',False),
 'kl':('memory','name','l','check',True),'km':('memory','sound','m','check',True),
 'pm':('memory','sound','m','probe',False),
}
def run(seq, need_s=4, need_d=2, need_c=1):
    p=0.2; n=0; succ=0; days=set(); mdays=set(); cues=set(); groups=set(); checks=0; fresh=None; log=[]
    review_day=None; good_reviews=[]
    for k,(day,item,res,h) in enumerate(seq):
        mode,cue,g,purpose,chk=ITEMS[item]
        probe = purpose=='probe'
        eff = min(h+1,3) if mode=='copy' else h
        correct = res=='c'
        w = CREDIT[eff] if correct else (1.0 if res=='x' else 0.3)
        p=bkt(p,correct,w); n+=1
        if not probe and mode!='copy' and review_day!=day:
            review_day=day; good_reviews.append((day, correct and eff<=1))
        if correct and eff==0 and not probe:
            succ+=1; days.add(day)
            if mode=='memory': mdays.add(day); cues.add(cue); groups.add(g)
            if chk: checks+=1
        why=[]
        if fresh is None:
            if p<BAR: why.append('p')
            if succ<need_s: why.append('successes')
            if len(days)<need_d: why.append('days')
            if len(mdays)<2 or cues!={'sound','name'}: why.append('memory-days-or-cues')
            if checks<need_c: why.append('checks')
            if groups!={'m','l'}: why.append('coverage')
            if not why: fresh=k+1
        log.append(f"{k+1}:{item}{'' if correct else '('+res+')'}h{h} p={p:.3f} s={succ} md={len(mdays)} cues={''.join(sorted(c[0] for c in cues))} {'FRESH' if fresh==k+1 else ''}")
    return p,succ,sorted(mdays),cues,checks,fresh,why,log
V={
'V1 copies only, 3 days':[(1,'cm','c',0),(1,'cl','c',0),(2,'cm','c',0),(2,'cl','c',0),(3,'cm','c',0),(3,'cl','c',0)],
'V2 memory by sound only, 3 days':[(1,'ms','c',0),(1,'ls','c',0),(2,'ms','c',0),(2,'km','c',0),(3,'ls','c',0)],
'V3 both cues, one day':[(1,'ms','c',0),(1,'ln','c',0),(1,'mn','c',0),(1,'kl','c',0),(1,'ls','c',0)],
'V4 the normal path':[(1,'cm','c',0),(1,'cl','c',0),(1,'ms','c',0),(1,'ln','c',0),(2,'mn','c',0),(2,'kl','c',0)],
'V5 memory with the start dot':[(1,'ms','c',1),(1,'ln','c',1),(2,'mn','c',1),(2,'kl','c',1),(3,'ls','c',1)],
'V6 one letter only':[(1,'ms','c',0),(1,'mn','c',0),(2,'ms','c',0),(2,'km','c',0),(2,'mn','c',0)],
'V7 probe does not count':[(1,'ms','c',0),(1,'ln','c',0),(2,'pm','c',0),(2,'mn','c',0)],
'V8 a miss then right':[(1,'ms','x',0),(1,'ms','c',1),(1,'ln','c',0),(2,'mn','c',0),(2,'ls','c',0),(2,'kl','c',0)],
'V9 copy with hints':[(1,'cm','c',1)],
'V9b copy with level 2':[(1,'cm','c',2)],
'V10 hint 3 memory':[(1,'ms','c',3)],
'V11 day1 both cues, day2 sound':[(1,'ms','c',0),(1,'ln','c',0),(2,'ls','c',0),(2,'km','c',0)],
}
for name,seq in V.items():
    p,s,md,cues,ch,fresh,why,log=run(seq)
    print('==',name,'| fresh at',fresh,'| missing',why)
    for l in log: print('   ',l)
print('== CORE')
seq=[(1,'cm','c',0),(1,'cl','c',0),(1,'ms','c',0),(1,'ln','c',0),(2,'mn','c',0),(2,'kl','c',0),(2,'ls','c',0),(3,'km','c',0)]
p,s,md,cues,ch,fresh,why,log=run(seq,need_s=6,need_c=2)
print('fresh at',fresh,why); [print('  ',l) for l in log]
print('== probe then memory wrong')
seq=[(1,'pm','c',0)]
print(run(seq)[7])
seq=[(1,'ms','x',0)]
print(run(seq)[7])
seq=[(1,'ms','c',1)]
print(run(seq)[7])
