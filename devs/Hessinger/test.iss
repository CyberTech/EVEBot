function main()
{
variable int NumSkills
variable index:skill MySkills
NumSkills:Set[${Me.GetSkills[MySkills]}]
echo ${NumSkills}
}